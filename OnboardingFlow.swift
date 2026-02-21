import SwiftUI
import MapKit
import FirebaseFirestore

// MARK: - Onboarding Data Model

struct OnboardingData {
    var firstName: String = ""
    var lastName: String = ""
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

        if !firstName.isEmpty {
            dict["firstName"] = firstName
        }

        if !lastName.isEmpty {
            dict["lastName"] = lastName
        }

        if let birthDate = birthDate {
            dict["birthDate"] = Timestamp(date: birthDate)
        }

        if let birthTime = birthTime {
            dict["birthTime"] = Timestamp(date: birthTime)
        }

        dict["isBirthTimeUnknown"] = isBirthTimeUnknown

        if !birthCity.isEmpty {
            dict["birthLocation"] = birthCity
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

    var next: OnboardingStep? {
        let steps = Self.allCases
        guard let index = steps.firstIndex(of: self),
              index + 1 < steps.count else { return nil }
        return steps[index + 1]
    }

    var previous: OnboardingStep? {
        let steps = Self.allCases
        guard let index = steps.firstIndex(of: self),
              index > 0 else { return nil }
        return steps[index - 1]
    }
}

// MARK: - Onboarding Flow Coordinator

struct OnboardingFlow: View {
    @State private var currentStep: OnboardingStep = .arrival
    @State private var data = OnboardingData()
    @State private var isVisible = false
    @State private var isReturningUser: Bool = false
    @State private var isSaving = false
    @State private var saveError: String?
    @State private var authenticatedUid: String?
    @EnvironmentObject private var authService: AuthService

    let onboardingService: OnboardingServiceProtocol
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
                        AccountCreationView(data: $data, onBack: goBack, onComplete: { uid in
                            authenticatedUid = uid
                            saveOnboardingDataThenComplete()
                        })
                    }
                }
            }
            .opacity(isVisible ? 1 : 0)

            if isSaving {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()

                VStack(spacing: 16) {
                    if let saveError {
                        Text(saveError)
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(Color(red: 0.9, green: 0.4, blue: 0.4))
                            .multilineTextAlignment(.center)

                        Button {
                            saveOnboardingDataThenComplete()
                        } label: {
                            Text("Retry")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(AppTheme.earth)
                                .padding(.horizontal, 32)
                                .padding(.vertical, 14)
                                .background(AppTheme.textPrimary)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    } else {
                        ProgressView()
                            .tint(AppTheme.textPrimary)
                    }
                }
                .padding(32)
                .background(AppTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
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
            if let next = currentStep.next {
                currentStep = next
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
            if let previous = currentStep.previous {
                currentStep = previous
            }

            withAnimation(.easeInOut(duration: 0.25)) {
                isVisible = true
            }
        }
    }

    private func saveOnboardingDataThenComplete() {
        let userId = authenticatedUid ?? authService.currentUserId
        isSaving = true
        saveError = nil
        Task {
            do {
                try await onboardingService.saveOnboardingData(data, userId: userId)
                if let userId {
                    try await onboardingService.migrateAnonymousData(toUserId: userId)
                }
                isSaving = false
                onComplete()
            } catch {
                isSaving = false
                saveError = "Could not save your data. Please try again."
            }
        }
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
                .accessibilityIdentifier("arrival.loginButton")
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
                        }

                        Text(knowsBirthTime ? "Approximate time is okay." : "You can add this in settings.")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(AppTheme.textSecondary)
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
                                    .frame(maxWidth: .infinity)
                                    .contentShape(Rectangle())
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
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(AppTheme.textPrimary)
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
    @Binding var data: OnboardingData
    var onBack: () -> Void
    var onComplete: (_ uid: String) -> Void

    @EnvironmentObject private var authService: AuthService
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showEmailForm = false
    @State private var isVisible = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    if showEmailForm {
                        showEmailForm = false
                        errorMessage = nil
                    } else {
                        onBack()
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(AppTheme.textPrimary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Back")
                .disabled(isLoading)
                Spacer()
            }
            .padding(.horizontal, 8)

            Spacer()

            VStack(spacing: 16) {
                Text("Keep your timing context over time.")
                    .font(.system(size: 26, weight: .medium))
                    .foregroundColor(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)

                if let errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(Color(red: 0.9, green: 0.4, blue: 0.4))
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 40)
            .opacity(isVisible ? 1 : 0)

            Spacer()

            if showEmailForm {
                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        TextField("First name", text: $data.firstName)
                            .font(.system(size: 17, weight: .regular))
                            .foregroundColor(AppTheme.textPrimary)
                            .tint(AppTheme.textPrimary)
                            .textContentType(.givenName)
                            .padding(.vertical, 14)
                            .padding(.horizontal, 16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(AppTheme.textPrimary.opacity(0.3), lineWidth: 1)
                            )
                            .disabled(isLoading)

                        TextField("Last name", text: $data.lastName)
                            .font(.system(size: 17, weight: .regular))
                            .foregroundColor(AppTheme.textPrimary)
                            .tint(AppTheme.textPrimary)
                            .textContentType(.familyName)
                            .padding(.vertical, 14)
                            .padding(.horizontal, 16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(AppTheme.textPrimary.opacity(0.3), lineWidth: 1)
                            )
                            .disabled(isLoading)
                    }

                    TextField("Email", text: $email)
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(AppTheme.textPrimary)
                        .tint(AppTheme.textPrimary)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding(.vertical, 14)
                        .padding(.horizontal, 16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(AppTheme.textPrimary.opacity(0.3), lineWidth: 1)
                        )
                        .disabled(isLoading)

                    SecureField("Password", text: $password)
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(AppTheme.textPrimary)
                        .tint(AppTheme.textPrimary)
                        .textContentType(.newPassword)
                        .padding(.vertical, 14)
                        .padding(.horizontal, 16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(AppTheme.textPrimary.opacity(0.3), lineWidth: 1)
                        )
                        .disabled(isLoading)

                    Button {
                        createAccount()
                    } label: {
                        Group {
                            if isLoading {
                                ProgressView()
                                    .tint(AppTheme.earth)
                            } else {
                                Text("Create Account")
                                    .font(.system(size: 17, weight: .medium))
                            }
                        }
                        .foregroundColor(AppTheme.earth)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            canCreateAccount
                                ? AppTheme.textPrimary
                                : AppTheme.textPrimary.opacity(0.3)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(!canCreateAccount)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
                .opacity(isVisible ? 1 : 0)
            } else {
                VStack(spacing: 12) {
                    Button {
                        showEmailForm = true
                    } label: {
                        Text("Continue with Email")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(AppTheme.earth)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(AppTheme.textPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
                .opacity(isVisible ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.easeIn(duration: 0.3).delay(0.1)) {
                isVisible = true
            }
        }
    }

    private var canCreateAccount: Bool {
        !isLoading && !data.firstName.isEmpty && !data.lastName.isEmpty && !email.isEmpty && password.count >= 6
    }

    private func createAccount() {
        guard canCreateAccount else { return }
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let uid = try await authService.createAccount(email: email, password: password)
                try? await authService.sendEmailVerification()
                onComplete(uid)
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

// MARK: - Login View

struct LoginView: View {
    var onBack: () -> Void
    var onComplete: () -> Void

    @EnvironmentObject private var authService: AuthService
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showEmailForm = false
    @State private var showForgotPassword = false
    @State private var isVisible = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    if showForgotPassword {
                        showForgotPassword = false
                        errorMessage = nil
                    } else if showEmailForm {
                        showEmailForm = false
                        errorMessage = nil
                    } else {
                        onBack()
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(AppTheme.textPrimary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Back")
                .disabled(isLoading)
                Spacer()
            }
            .padding(.horizontal, 8)

            Spacer()

            VStack(spacing: 16) {
                Text(showForgotPassword ? "Reset your password." : "Welcome back.")
                    .font(.system(size: 26, weight: .medium))
                    .foregroundColor(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier("login.title")

                if let errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(Color(red: 0.9, green: 0.4, blue: 0.4))
                        .multilineTextAlignment(.center)
                        .accessibilityIdentifier("login.errorMessage")
                }
            }
            .padding(.horizontal, 40)
            .opacity(isVisible ? 1 : 0)

            Spacer()

            if showForgotPassword {
                forgotPasswordContent
            } else if showEmailForm {
                VStack(spacing: 16) {
                    TextField("Email", text: $email)
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(AppTheme.textPrimary)
                        .tint(AppTheme.textPrimary)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding(.vertical, 14)
                        .padding(.horizontal, 16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(AppTheme.textPrimary.opacity(0.3), lineWidth: 1)
                        )
                        .disabled(isLoading)
                        .accessibilityIdentifier("login.emailField")

                    SecureField("Password", text: $password)
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(AppTheme.textPrimary)
                        .tint(AppTheme.textPrimary)
                        .textContentType(.password)
                        .padding(.vertical, 14)
                        .padding(.horizontal, 16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(AppTheme.textPrimary.opacity(0.3), lineWidth: 1)
                        )
                        .disabled(isLoading)
                        .accessibilityIdentifier("login.passwordField")

                    Button {
                        signIn()
                    } label: {
                        Group {
                            if isLoading {
                                ProgressView()
                                    .tint(AppTheme.earth)
                            } else {
                                Text("Sign In")
                                    .font(.system(size: 17, weight: .medium))
                            }
                        }
                        .foregroundColor(AppTheme.earth)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            (!isLoading && !email.isEmpty && !password.isEmpty)
                                ? AppTheme.textPrimary
                                : AppTheme.textPrimary.opacity(0.3)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .accessibilityIdentifier("login.signInButton")
                    .disabled(isLoading || email.isEmpty || password.isEmpty)

                    Button {
                        showForgotPassword = true
                        errorMessage = nil
                    } label: {
                        Text("Forgot password?")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
                .opacity(isVisible ? 1 : 0)
            } else {
                VStack(spacing: 12) {
                    Button {
                        showEmailForm = true
                    } label: {
                        Text("Continue with Email")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(AppTheme.earth)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(AppTheme.textPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .accessibilityIdentifier("login.continueWithEmailButton")
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
                .opacity(isVisible ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.easeIn(duration: 0.3).delay(0.1)) {
                isVisible = true
            }
        }
    }

    @State private var resetEmailSent = false

    private var forgotPasswordContent: some View {
        VStack(spacing: 16) {
            if resetEmailSent {
                VStack(spacing: 12) {
                    Image(systemName: "envelope.badge.shield.half.filled")
                        .font(.system(size: 32))
                        .foregroundColor(AppTheme.textPrimary)

                    Text("Check your email for a reset link.")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)

                    Button {
                        showForgotPassword = false
                        resetEmailSent = false
                        errorMessage = nil
                    } label: {
                        Text("Back to Sign In")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(AppTheme.textPrimary)
                            .underline()
                    }
                    .padding(.top, 8)
                }
            } else {
                TextField("Email", text: $email)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(AppTheme.textPrimary)
                    .tint(AppTheme.textPrimary)
                    .textContentType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding(.vertical, 14)
                    .padding(.horizontal, 16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(AppTheme.textPrimary.opacity(0.3), lineWidth: 1)
                    )
                    .disabled(isLoading)

                Button {
                    sendPasswordReset()
                } label: {
                    Group {
                        if isLoading {
                            ProgressView()
                                .tint(AppTheme.earth)
                        } else {
                            Text("Send Reset Link")
                                .font(.system(size: 17, weight: .medium))
                        }
                    }
                    .foregroundColor(AppTheme.earth)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        (!isLoading && !email.isEmpty)
                            ? AppTheme.textPrimary
                            : AppTheme.textPrimary.opacity(0.3)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(isLoading || email.isEmpty)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 48)
        .opacity(isVisible ? 1 : 0)
    }

    private func signIn() {
        guard !email.isEmpty, !password.isEmpty else { return }
        isLoading = true
        errorMessage = nil
        Task {
            do {
                try await authService.signIn(email: email, password: password)
                onComplete()
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    private func sendPasswordReset() {
        guard !email.isEmpty else { return }
        isLoading = true
        errorMessage = nil
        Task {
            do {
                try await authService.sendPasswordReset(email: email)
                resetEmailSent = true
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingFlow(onboardingService: OnboardingService(), onComplete: {})
}
