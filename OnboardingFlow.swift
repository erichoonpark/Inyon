import SwiftUI
import MapKit
import FirebaseFirestore
import FirebaseAuth

// MARK: - Onboarding Data Model

struct OnboardingData {
    var birthDate: Date?
    var birthTime: Date?
    var isBirthTimeUnknown: Bool = false
    var birthCity: String = ""
    var personalAnchors: Set<PersonalAnchor> = []

    func toFirestoreData() -> [String: Any] {
        var dict: [String: Any] = [
            "createdAt": FieldValue.serverTimestamp(),
            "personalAnchors": personalAnchors.map { $0.rawValue }
        ]

        if let birthDate = birthDate {
            dict["birthDate"] = Timestamp(date: birthDate)
        }

        if let birthTime = birthTime {
            dict["birthTime"] = Timestamp(date: birthTime)
        }

        dict["isBirthTimeUnknown"] = isBirthTimeUnknown

        if !birthCity.isEmpty {
            dict["birthCity"] = birthCity
        }

        return dict
    }
}

enum PersonalAnchor: String, CaseIterable, Identifiable {
    case direction = "Direction"
    case energy = "Energy"
    case love = "Love"
    case work = "Work"
    case rest = "Rest"

    var id: String { rawValue }
}

enum OnboardingStep: Int, CaseIterable {
    case arrival
    case birthContext
    case personalAnchor
    case accountCreation
}

// MARK: - Onboarding Flow Coordinator

struct OnboardingFlow: View {
    @State private var currentStep: OnboardingStep = .arrival
    @State private var data = OnboardingData()
    @State private var isVisible = false
    @State private var isReturningUser: Bool = false

    var onComplete: () -> Void

    var body: some View {
        ZStack {
            AppTheme.earth
                .ignoresSafeArea()

            Group {
                switch currentStep {
                case .arrival:
                    ArrivalView(onGetStarted: advanceToNext, onLogin: {
                        isReturningUser = true
                        navigateTo(.accountCreation)
                    })
                case .birthContext:
                    BirthContextView(data: $data, onBack: goBack, onContinue: advanceToNext)
                case .personalAnchor:
                    PersonalAnchorView(data: $data, onBack: goBack, onContinue: advanceToNext, onSkip: advanceToNext)
                case .accountCreation:
                    if isReturningUser {
                        LoginView(onBack: {
                            isReturningUser = false
                            navigateTo(.arrival)
                        }, onComplete: onComplete)
                    } else {
                        AccountCreationView(data: data, onBack: goBack, onComplete: {
                            saveOnboardingData()
                            onComplete()
                        })
                    }
                }
            }
            .opacity(isVisible ? 1 : 0)
        }
        .onAppear {
            withAnimation(.easeIn(duration: 0.25)) {
                isVisible = true
            }
        }
    }

    private func navigateTo(_ step: OnboardingStep) {
        withAnimation(.easeInOut(duration: 0.25)) {
            isVisible = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            currentStep = step

            withAnimation(.easeInOut(duration: 0.25)) {
                isVisible = true
            }
        }
    }

    private func advanceToNext() {
        withAnimation(.easeInOut(duration: 0.25)) {
            isVisible = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            if let nextIndex = OnboardingStep.allCases.firstIndex(of: currentStep),
               nextIndex + 1 < OnboardingStep.allCases.count {
                currentStep = OnboardingStep.allCases[nextIndex + 1]
            }

            withAnimation(.easeInOut(duration: 0.25)) {
                isVisible = true
            }
        }
    }

    private func goBack() {
        withAnimation(.easeInOut(duration: 0.25)) {
            isVisible = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            if let currentIndex = OnboardingStep.allCases.firstIndex(of: currentStep),
               currentIndex > 0 {
                currentStep = OnboardingStep.allCases[currentIndex - 1]
            }

            withAnimation(.easeInOut(duration: 0.25)) {
                isVisible = true
            }
        }
    }

    private func saveOnboardingData() {
        let db = Firestore.firestore()
        let firestoreData = data.toFirestoreData()

        let documentRef: DocumentReference

        if let uid = Auth.auth().currentUser?.uid {
            documentRef = db.collection("users").document(uid)
                .collection("onboarding").document("context")
        } else {
            let anonymousId = UUID().uuidString
            documentRef = db.collection("onboarding").document("anonymous")
                .collection("users").document(anonymousId)
        }

        documentRef.setData(firestoreData) { _ in }
    }
}

// MARK: - Screen 1: Arrival / Orientation

struct ArrivalView: View {
    var onGetStarted: () -> Void
    var onLogin: () -> Void
    @State private var isVisible = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                Text("Inyon offers insight about timing & balance.")
                    .font(.system(size: 26, weight: .medium))
                    .foregroundColor(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .fixedSize(horizontal: false, vertical: true)

                Text("You'll get a short daily view of timing and context.")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 40)
            .opacity(isVisible ? 1 : 0)

            Spacer()

            VStack(spacing: 16) {
                Button {
                    onGetStarted()
                } label: {
                    Text("Get Started")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(AppTheme.earth)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(AppTheme.textPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Button {
                    onLogin()
                } label: {
                    Text("Already have an account? Log in")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
            .opacity(isVisible ? 1 : 0)
        }
        .onAppear {
            withAnimation(.easeIn(duration: 0.3).delay(0.1)) {
                isVisible = true
            }
        }
    }
}

// MARK: - City Search Completer

class CitySearchCompleter: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var results: [MKLocalSearchCompletion] = []
    private let completer = MKLocalSearchCompleter()

    override init() {
        super.init()
        completer.resultTypes = .address
        completer.delegate = self
    }

    func search(_ query: String) {
        guard !query.isEmpty else {
            results = []
            return
        }
        completer.queryFragment = query
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        results = completer.results.filter { !$0.subtitle.isEmpty }
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        results = []
    }
}

// MARK: - Screen 2: Birth Context

struct BirthContextView: View {
    @Binding var data: OnboardingData
    var onBack: () -> Void
    var onContinue: () -> Void

    @State private var selectedDate = Date()
    @State private var selectedTime = Date()
    @State private var hasSelectedDate = false
    @State private var hasSelectedTime = false
    @State private var knowsBirthTime = true
    @State private var showingDatePicker = false
    @State private var showingTimePicker = false
    @State private var cityQuery = ""
    @StateObject private var cityCompleter = CitySearchCompleter()
    @State private var isVisible = false

    private var formattedDate: String {
        selectedDate.formatted(date: .long, time: .omitted)
    }

    private var formattedTime: String {
        selectedTime.formatted(date: .omitted, time: .shortened)
    }

    private var canContinue: Bool {
        hasSelectedDate && !data.birthCity.isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    onBack()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(AppTheme.textPrimary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Back")
                Spacer()
            }
            .padding(.horizontal, 8)

            Spacer()
                .frame(height: 36)

            VStack(alignment: .leading, spacing: 32) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Saju looks at the moment you entered the world.")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(AppTheme.textPrimary)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("This helps Inyon determine timing patterns")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(AppTheme.textSecondary)
                }

                VStack(alignment: .leading, spacing: 24) {
                    // Birth Date
                    VStack(alignment: .leading, spacing: 8) {
                        Text("BIRTH DATE")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .tracking(1.2)
                            .foregroundColor(AppTheme.textSecondary)

                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showingDatePicker.toggle()
                                showingTimePicker = false
                            }
                        } label: {
                            Text(hasSelectedDate ? formattedDate : "Select date")
                                .font(.system(size: 17, weight: .regular))
                                .foregroundColor(hasSelectedDate ? AppTheme.textPrimary : AppTheme.textSecondary)
                        }

                        if showingDatePicker {
                            DatePicker(
                                "",
                                selection: $selectedDate,
                                in: ...Date(),
                                displayedComponents: .date
                            )
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                            .colorScheme(.dark)
                            .onChange(of: selectedDate) { _, _ in
                                hasSelectedDate = true
                            }
                        }
                    }

                    // Birth Time
                    VStack(alignment: .leading, spacing: 12) {
                        Text("BIRTH TIME")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .tracking(1.2)
                            .foregroundColor(AppTheme.textSecondary)

                        if knowsBirthTime {
                            HStack(spacing: 16) {
                                Button {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        showingTimePicker.toggle()
                                        showingDatePicker = false
                                    }
                                } label: {
                                    Text(hasSelectedTime ? formattedTime : "Select time")
                                        .font(.system(size: 17, weight: .regular))
                                        .foregroundColor(hasSelectedTime ? AppTheme.textPrimary : AppTheme.textSecondary)
                                }

                                Button {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        knowsBirthTime = false
                                        showingTimePicker = false
                                    }
                                } label: {
                                    Text("Not sure")
                                        .font(.system(size: 15, weight: .regular))
                                        .foregroundColor(AppTheme.textSecondary)
                                        .underline()
                                }
                            }

                            if showingTimePicker {
                                DatePicker(
                                    "",
                                    selection: $selectedTime,
                                    displayedComponents: .hourAndMinute
                                )
                                .datePickerStyle(.wheel)
                                .labelsHidden()
                                .colorScheme(.dark)
                                .onChange(of: selectedTime) { _, _ in
                                    hasSelectedTime = true
                                }
                            }
                        } else {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 16) {
                                    Text("Skipped")
                                        .font(.system(size: 17, weight: .regular))
                                        .foregroundColor(AppTheme.textSecondary)

                                    Button {
                                        knowsBirthTime = true
                                    } label: {
                                        Text("Add later")
                                            .font(.system(size: 15, weight: .regular))
                                            .foregroundColor(AppTheme.textSecondary)
                                            .underline()
                                    }
                                }

                                Text("You can add this in settings.")
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundColor(AppTheme.textSecondary)
                            }
                        }

                        if knowsBirthTime {
                            Text("Approximate time is okay.")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }

                    // Birth City
                    VStack(alignment: .leading, spacing: 8) {
                        Text("BIRTH CITY")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .tracking(1.2)
                            .foregroundColor(AppTheme.textSecondary)

                        VStack(alignment: .leading, spacing: 0) {
                            if data.birthCity.isEmpty {
                                TextField("Enter city", text: $cityQuery)
                                    .font(.system(size: 17, weight: .regular))
                                    .foregroundColor(AppTheme.textPrimary)
                                    .tint(AppTheme.textPrimary)
                                    .autocorrectionDisabled()
                                    .onChange(of: cityQuery) { _, newValue in
                                        cityCompleter.search(newValue)
                                    }
                            } else {
                                HStack(spacing: 16) {
                                    Text(data.birthCity)
                                        .font(.system(size: 17, weight: .regular))
                                        .foregroundColor(AppTheme.textPrimary)

                                    Button {
                                        data.birthCity = ""
                                        cityQuery = ""
                                    } label: {
                                        Text("Change")
                                            .font(.system(size: 15, weight: .regular))
                                            .foregroundColor(AppTheme.textSecondary)
                                            .underline()
                                    }
                                }
                            }

                            Rectangle()
                                .fill(AppTheme.textPrimary.opacity(0.3))
                                .frame(height: 1)
                                .padding(.top, 8)
                        }

                        if data.birthCity.isEmpty {
                            ForEach(cityCompleter.results.prefix(3), id: \.self) { result in
                                let city = [result.title, result.subtitle]
                                    .filter { !$0.isEmpty }
                                    .joined(separator: ", ")

                                Button {
                                    data.birthCity = city
                                    cityQuery = city
                                    cityCompleter.results = []
                                } label: {
                                    Text(city)
                                        .font(.system(size: 15, weight: .regular))
                                        .foregroundColor(AppTheme.textSecondary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.vertical, 6)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .opacity(isVisible ? 1 : 0)

            Spacer()

            Button {
                data.birthDate = hasSelectedDate ? selectedDate : nil
                data.birthTime = (knowsBirthTime && hasSelectedTime) ? selectedTime : nil
                data.isBirthTimeUnknown = !knowsBirthTime
                onContinue()
            } label: {
                Text("Continue")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(AppTheme.earth)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(canContinue ? AppTheme.textPrimary : AppTheme.textPrimary.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(!canContinue)
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
            .opacity(isVisible ? 1 : 0)
        }
        .onAppear {
            withAnimation(.easeIn(duration: 0.3).delay(0.1)) {
                isVisible = true
            }
        }
    }
}

// MARK: - Screen 3: Personal Anchor

struct PersonalAnchorView: View {
    @Binding var data: OnboardingData
    var onBack: () -> Void
    var onContinue: () -> Void
    var onSkip: () -> Void

    @State private var selectedAnchors: Set<PersonalAnchor> = []
    @State private var isVisible = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    onBack()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(AppTheme.textPrimary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Back")
                Spacer()
            }
            .padding(.horizontal, 8)

            Spacer()
                .frame(height: 36)

            VStack(alignment: .leading, spacing: 40) {
                Text("What feels most present in your life right now?")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(AppTheme.textPrimary)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: 0) {
                    ForEach(PersonalAnchor.allCases) { anchor in
                        Button {
                            if selectedAnchors.contains(anchor) {
                                selectedAnchors.remove(anchor)
                            } else {
                                selectedAnchors.insert(anchor)
                            }
                        } label: {
                            HStack {
                                Text(anchor.rawValue)
                                    .font(.system(size: 19, weight: .regular))
                                    .foregroundColor(
                                        selectedAnchors.contains(anchor)
                                            ? AppTheme.textPrimary
                                            : AppTheme.textSecondary
                                    )

                                Spacer()

                                if selectedAnchors.contains(anchor) {
                                    Rectangle()
                                        .fill(AppTheme.textPrimary)
                                        .frame(width: 20, height: 2)
                                }
                            }
                            .padding(.vertical, 18)
                            .contentShape(Rectangle())
                        }

                        if anchor != PersonalAnchor.allCases.last {
                            Rectangle()
                                .fill(AppTheme.divider)
                                .frame(height: 1)
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .opacity(isVisible ? 1 : 0)

            Spacer()

            VStack(spacing: 12) {
                Button {
                    data.personalAnchors = selectedAnchors
                    onContinue()
                } label: {
                    Text("Continue")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(AppTheme.earth)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(AppTheme.textPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Button {
                    onSkip()
                } label: {
                    Text("Skip")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
            .opacity(isVisible ? 1 : 0)
        }
        .onAppear {
            withAnimation(.easeIn(duration: 0.3).delay(0.1)) {
                isVisible = true
            }
        }
    }
}

// MARK: - Screen 4: Account Creation

struct AccountCreationView: View {
    var data: OnboardingData
    var onBack: () -> Void
    var onComplete: () -> Void

    @State private var isVisible = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    onBack()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(AppTheme.textPrimary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Back")
                Spacer()
            }
            .padding(.horizontal, 8)

            Spacer()

            VStack(spacing: 16) {
                Text("Keep your timing context over time.")
                    .font(.system(size: 26, weight: .medium))
                    .foregroundColor(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 40)
            .opacity(isVisible ? 1 : 0)

            Spacer()

            VStack(spacing: 12) {
                // Apple Sign In
                Button {
                    // TODO: Implement Apple Sign In
                    onComplete()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "apple.logo")
                            .font(.system(size: 18))
                        Text("Continue with Apple")
                            .font(.system(size: 17, weight: .medium))
                    }
                    .foregroundColor(AppTheme.earth)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(AppTheme.textPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                // Email Sign In
                Button {
                    // TODO: Implement Email Sign In
                    onComplete()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "envelope")
                            .font(.system(size: 16))
                        Text("Continue with Email")
                            .font(.system(size: 17, weight: .medium))
                    }
                    .foregroundColor(AppTheme.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(AppTheme.textPrimary.opacity(0.3), lineWidth: 1)
                    )
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
            .opacity(isVisible ? 1 : 0)
        }
        .onAppear {
            withAnimation(.easeIn(duration: 0.3).delay(0.1)) {
                isVisible = true
            }
        }
    }
}

// MARK: - Login View

struct LoginView: View {
    var onBack: () -> Void
    var onComplete: () -> Void

    @State private var isVisible = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    onBack()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(AppTheme.textPrimary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Back")
                Spacer()
            }
            .padding(.horizontal, 8)

            Spacer()

            VStack(spacing: 16) {
                Text("Welcome back.")
                    .font(.system(size: 26, weight: .medium))
                    .foregroundColor(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 40)
            .opacity(isVisible ? 1 : 0)

            Spacer()

            VStack(spacing: 12) {
                // Apple Sign In
                Button {
                    // TODO: Implement Apple Sign In
                    onComplete()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "apple.logo")
                            .font(.system(size: 18))
                        Text("Continue with Apple")
                            .font(.system(size: 17, weight: .medium))
                    }
                    .foregroundColor(AppTheme.earth)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(AppTheme.textPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                // Email Sign In
                Button {
                    // TODO: Implement Email Sign In
                    onComplete()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "envelope")
                            .font(.system(size: 16))
                        Text("Continue with Email")
                            .font(.system(size: 17, weight: .medium))
                    }
                    .foregroundColor(AppTheme.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(AppTheme.textPrimary.opacity(0.3), lineWidth: 1)
                    )
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
            .opacity(isVisible ? 1 : 0)
        }
        .onAppear {
            withAnimation(.easeIn(duration: 0.3).delay(0.1)) {
                isVisible = true
            }
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingFlow(onComplete: {})
}
