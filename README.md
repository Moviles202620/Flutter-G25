# 🐐 Goatly – Flutter App

Mobile application developed in Flutter for the course **Construcción de Aplicaciones Móviles**.

Goatly is a LinkedIn-style mobile platform designed for **occasional job opportunities at Universidad de los Andes**. It centralizes job postings, applications, and candidate management, replacing the current email-based and low-visibility system.

---

## 📌 About

The problem Goatly addresses is the inefficient and poorly communicated process for occasional jobs at the university. Currently:

- Job postings have low visibility.
- Applications are handled through scattered platforms and mass emails.
- Students lack transparency about their application status.
- Employers manage candidates manually and inefficiently.

Goatly provides:

- A centralized job feed.
- A structured application system.
- Real-time application status tracking.
- Employer tools for candidate management.

---

## 🎯 Objective

To improve visibility, organization, and efficiency in the occasional job application process at Universidad de los Andes by providing a mobile-first experience for both students and employers.

---

## ✨ Features (MVP)

### 👩‍🎓 Student Flow
- User authentication (Login / Register)
- Browse job feed
- Filter job opportunities
- View job details
- Apply to jobs
- Track application status

### 👨‍🏫 Employer Flow
- Create job postings
- View applicants per job
- Update application status (Accepted / Rejected / In Review)

---

## 🏗 Project Structure

The project follows a **feature-based architecture** with clear separation of concerns.

```
lib/
├── app/ # App configuration and routing
│ ├── app.dart
│ └── router.dart
│
├── features/ # Feature-based organization
│ ├── auth/
│ ├── jobs/
│ ├── applications/
│ └── employer/
│
├── models/ # Domain models
│ ├── job.dart
│ ├── application.dart
│ └── user.dart
│
├── services/ # Business logic and API interaction
│ ├── jobs_service.dart
│ ├── applications_service.dart
│ └── auth_service.dart
│
├── mock/ # Mock data for development
│ ├── mock_jobs.dart
│ └── mock_applications.dart
│
├── theme/ # Design system
│ ├── colors.dart
│ ├── typography.dart
│ └── theme.dart
│
├── widgets/ # Reusable UI components
│ ├── job_card.dart
│ ├── empty_state.dart
│ └── main_scaffold.dart
│
└── main.dart

```

---

## 🎨 Design System

Goatly follows a consistent and scalable design system:

- Primary Color: Institutional neutral tone
- Accent Color: Call-to-action highlight
- Typography: Consistent font family across the entire app
- Reusable components for:
  - Buttons
  - Cards
  - Text fields
  - Status badges

All styles are centralized inside the `/theme` directory to ensure visual consistency.

---

## 🔄 State Management

The application uses:

- **Riverpod** for state management
- Feature-based providers
- Clear separation between UI and business logic

This ensures scalability, maintainability, and clean architecture practices.

---

## 🔌 Backend Integration Strategy

The frontend is developed using a **mock-first approach**.

1. Mock repositories simulate backend responses.
2. UI and user flows are validated.
3. Mock services will later be replaced with real API integrations.

### Planned API Endpoints

- `GET /jobs`
- `GET /jobs/{id}`
- `POST /jobs`
- `POST /applications`
- `GET /applications?userId=...`
- `GET /jobs/{id}/candidates`
- `PATCH /applications/{id}`

---

## 🚀 Getting Started

### 1️⃣ Clone the repository
```
git clone https://github.com/Moviles202620/Flutter-G25.git
```

### 2️⃣ Install dependencies
```
flutter pub get
```


### 3️⃣ Run the app
```
flutter run
```


---

## 🧪 Development Guidelines

- Follow feature-based folder structure.
- Use `const` constructors whenever possible.
- Keep widgets small and reusable.
- Avoid business logic inside UI files.
- Services handle data; UI only renders state.
- Maintain consistent naming conventions.
- All new features must be developed in separate branches.

---

## 👥 Team

Flutter Team – G25  
Construcción de Aplicaciones Móviles  
Universidad de los Andes  

---

## 📚 Course Context

This project is part of the academic development process for:

**Construcción de Aplicaciones Móviles – 2026-10**  
Universidad de los Andes

---

## 📌 Status

🚧 In active development – MVP Phase
