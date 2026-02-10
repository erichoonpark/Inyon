import SwiftUI

struct SignupData {
    var firstName: String = ""
    var lastName: String = ""
    var email: String = ""
    var password: String = ""
    var birthDate: Date = Date()
    var birthTime: Date? = nil
    var birthTimeUnknown: Bool = false
    var birthLocation: String = ""
}

struct SignupFlowView: View {
    @EnvironmentObject private var authService: AuthService
    @State private var currentStep = 0
    @State private var data = SignupData()
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    private let userService = UserService()

    var body: some View {
        VStack(spacing: 0) {
            switch currentStep {
            case 0:
                NameStepView(
                    firstName: $data.firstName,
                    lastName: $data.lastName,
                    onNext: nextStep
                )
            case 1:
                EmailStepView(
                    email: $data.email,
                    onNext: nextStep,
                    onBack: previousStep
                )
            case 2:
                PasswordStepView(
                    password: $data.password,
                    onNext: nextStep,
                    onBack: previousStep
                )
            case 3:
                BirthDateStepView(
                    birthDate: $data.birthDate,
                    onNext: nextStep,
                    onBack: previousStep
                )
            case 4:
                BirthTimeStepView(
                    birthTime: $data.birthTime,
                    isUnknown: $data.birthTimeUnknown,
                    onNext: nextStep,
                    onBack: previousStep
                )
            case 5:
                BirthLocationStepView(
                    location: $data.birthLocation,
                    onNext: completeSignup,
                    onBack: previousStep,
                    isSubmitting: isSubmitting
                )
            default:
                EmptyView()
            }
        }
        .alert("Error", isPresented: .init(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func nextStep() {
        withAnimation {
            currentStep += 1
        }
    }

    private func previousStep() {
        withAnimation {
            currentStep -= 1
        }
    }

    private func completeSignup() {
        guard !isSubmitting else { return }
        isSubmitting = true

        Task {
            do {
                let userId = try await authService.createAccount(
                    email: data.email,
                    password: data.password
                )

                let user = User(
                    id: userId,
                    firstName: data.firstName,
                    lastName: data.lastName,
                    email: data.email,
                    birthDate: data.birthDate,
                    birthTime: data.birthTime,
                    birthTimeUnknown: data.birthTimeUnknown,
                    birthLocation: data.birthLocation
                )

                try await userService.createUser(user)
            } catch {
                errorMessage = error.localizedDescription
                isSubmitting = false
            }
        }
    }
}

// MARK: - Name Step

struct NameStepView: View {
    @Binding var firstName: String
    @Binding var lastName: String
    var onNext: () -> Void

    private var canContinue: Bool {
        !firstName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !lastName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()

            Text("What's your name?")
                .font(.title2)
                .fontWeight(.medium)

            Spacer().frame(height: 32)

            TextField("First name", text: $firstName)
                .textContentType(.givenName)
                .font(.body)
                .padding(.vertical, 12)

            Divider()

            TextField("Last name", text: $lastName)
                .textContentType(.familyName)
                .font(.body)
                .padding(.vertical, 12)

            Divider()

            Spacer()
            Spacer()

            SignupButton(title: "Continue", enabled: canContinue, action: onNext)
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 32)
    }
}

// MARK: - Email Step

struct EmailStepView: View {
    @Binding var email: String
    var onNext: () -> Void
    var onBack: () -> Void

    private var canContinue: Bool {
        !email.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SignupBackButton(action: onBack)

            Spacer()

            Text("What's your email?")
                .font(.title2)
                .fontWeight(.medium)

            Spacer().frame(height: 32)

            TextField("Email", text: $email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .font(.body)
                .padding(.vertical, 12)

            Divider()

            Spacer()
            Spacer()

            SignupButton(title: "Continue", enabled: canContinue, action: onNext)
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 32)
    }
}

// MARK: - Password Step

struct PasswordStepView: View {
    @Binding var password: String
    var onNext: () -> Void
    var onBack: () -> Void

    private var canContinue: Bool {
        password.count >= 6
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SignupBackButton(action: onBack)

            Spacer()

            Text("Create a password")
                .font(.title2)
                .fontWeight(.medium)

            Spacer().frame(height: 32)

            SecureField("Password", text: $password)
                .textContentType(.newPassword)
                .font(.body)
                .padding(.vertical, 12)

            Divider()

            Text("At least 6 characters")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 8)

            Spacer()
            Spacer()

            SignupButton(title: "Continue", enabled: canContinue, action: onNext)
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 32)
    }
}

// MARK: - Birth Date Step

struct BirthDateStepView: View {
    @Binding var birthDate: Date
    var onNext: () -> Void
    var onBack: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SignupBackButton(action: onBack)

            Spacer()

            Text("When were you born?")
                .font(.title2)
                .fontWeight(.medium)

            Spacer().frame(height: 32)

            DatePicker(
                "",
                selection: $birthDate,
                displayedComponents: .date
            )
            .datePickerStyle(.wheel)
            .labelsHidden()

            Spacer()
            Spacer()

            SignupButton(title: "Continue", enabled: true, action: onNext)
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 32)
    }
}

// MARK: - Birth Time Step

struct BirthTimeStepView: View {
    @Binding var birthTime: Date?
    @Binding var isUnknown: Bool
    var onNext: () -> Void
    var onBack: () -> Void

    @State private var selectedTime: Date = {
        var components = DateComponents()
        components.hour = 12
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }()

    private var canContinue: Bool {
        isUnknown || birthTime != nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SignupBackButton(action: onBack)

            Spacer()

            Text("What time were you born?")
                .font(.title2)
                .fontWeight(.medium)

            Spacer().frame(height: 32)

            if !isUnknown {
                DatePicker(
                    "",
                    selection: $selectedTime,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .onChange(of: selectedTime) { _, newValue in
                    birthTime = newValue
                }
            }

            Spacer().frame(height: 24)

            Button {
                isUnknown.toggle()
                if isUnknown {
                    birthTime = nil
                } else {
                    birthTime = selectedTime
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: isUnknown ? "checkmark.square.fill" : "square")
                        .font(.body)
                    Text("I don't know my birth time")
                        .font(.body)
                }
                .foregroundStyle(isUnknown ? .primary : .secondary)
            }
            .buttonStyle(.plain)

            Spacer()
            Spacer()

            SignupButton(title: "Continue", enabled: canContinue, action: onNext)
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 32)
        .onAppear {
            if !isUnknown && birthTime == nil {
                birthTime = selectedTime
            }
        }
    }
}

// MARK: - Birth Location Step

struct BirthLocationStepView: View {
    @Binding var location: String
    var onNext: () -> Void
    var onBack: () -> Void
    var isSubmitting: Bool = false

    private var canContinue: Bool {
        !location.trimmingCharacters(in: .whitespaces).isEmpty && !isSubmitting
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SignupBackButton(action: onBack)

            Spacer()

            Text("Where were you born?")
                .font(.title2)
                .fontWeight(.medium)

            Spacer().frame(height: 32)

            TextField("Search for a city", text: $location)
                .font(.body)
                .padding(.vertical, 12)

            Divider()

            Text("City-level location")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 8)

            Spacer()
            Spacer()

            SignupButton(
                title: isSubmitting ? "Creating account..." : "Complete",
                enabled: canContinue,
                action: onNext
            )
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 32)
    }
}

// MARK: - Shared Components

struct SignupButton: View {
    let title: String
    let enabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.body)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(enabled ? Color.primary : Color.secondary.opacity(0.3))
                .foregroundStyle(enabled ? Color(uiColor: .systemBackground) : .secondary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(!enabled)
    }
}

struct SignupBackButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(.body)
                .foregroundStyle(.primary)
        }
        .padding(.top, 16)
    }
}

#Preview {
    SignupFlowView()
}
