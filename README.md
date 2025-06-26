# Visits Tracker App

This project is a technical challenge solution for a Flutter Mobile Engineer role, implementing a "Visits Tracker" feature for a Route-to-Market (RTM) Sales Force Automation app.

## Table of Contents
- [Features](#features)
- [Architecture](#architecture)
- [Screenshots](#screenshots)
- [Setup Instructions](#setup-instructions)
- [API](#api)
- [Key Expectations Addressed](#key-expectations-addressed)
    - [Architecture & Scalability](#architecture--scalability)
    - [State & Navigation](#state--navigation)
    - [Data & API Layer](#data--api-layer)
    - [User Experience](#user-experience)
    - [Offline Handling](#offline-handling)
    - [Testing](#testing)
    - [CI/CD](#cicd)
- [Assumptions, Trade-offs, and Limitations](#assumptions-trade-offs-and-limitations)
- [Future Improvements](#future-improvements)

## Features
The app allows a sales representative to:
- Add a new visit by filling out a form.
- View a list of their customer visits.
- Track activities completed during the visit.
- View basic statistics related to their visits (e.g., how many completed).
- Search or filter visits by status and text.

## Architecture
This application follows a clean architecture approach, dividing the codebase into distinct layers:

1.  **Presentation Layer:** (UI & State Management)
    * Built with Flutter widgets.
    * State management is handled using `flutter_bloc` (or `cubit`), ensuring a clear separation of UI and business logic.
    * Navigation is managed using `go_router` for a declarative routing approach.
2.  **Domain Layer:** (Business Logic)
    * Contains core business entities (`Visit`, `Customer`, `Activity`) and use cases (`GetAllVisits`, `AddVisit`, `GetVisitStats`).
    * This layer is pure Dart, independent of any framework or data source.
    * Uses `dartz` for functional error handling (`Either<Failure, T>`).
3.  **Data Layer:** (Repository & Data Sources)
    * Defines abstract `Repository` interfaces in the domain and implements them here.
    * Communicates with the external Supabase REST API via `Dio` for remote data.
    * Handles data serialization/deserialization between API responses and domain entities using `Model` classes.
    * Maps network exceptions to domain `Failure` types.

![Application Architecture.png](assets/markdown/Application%20Architecture.png)
*Architecture Diagram*

**Why this architecture?**
-   **Separation of Concerns:** Each layer has a specific responsibility, leading to a more organized and understandable codebase.
-   **Testability:** The layers are independent, allowing for easy unit testing of business logic (use cases) and data interactions (repositories, data sources) without needing the UI or actual API calls.
-   **Scalability:** New features or changes in data sources (e.g., switching from Supabase to Firebase, or adding a local database) can be implemented with minimal impact on other layers.
-   **Maintainability:** Easier to debug, modify, and extend the application due to its modular nature.
-   **Onboarding:** New engineers can quickly grasp the project structure and contribute effectively.

## Screenshots
*(Include screenshots of your Flutter application here: Home Screen, Add Visit Screen, Search/Filter in action, Statistics)*

## Setup Instructions

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/teloorid/visits_tracker.git
    cd visits_tracker
    ```
2.  **Install Flutter dependencies:**
    ```bash
    flutter pub get
    ```
3.  **Generate code (for mockito, hive adapters if used):**
    ```bash
    flutter pub run build_runner build --delete-conflicting-outputs
    ```
4.  **Run the application:**
    ```bash
    flutter run
    ```
    (Ensure you have an Android emulator, iOS simulator, or a connected device.)

## API
The application consumes a RESTful API powered by Supabase.
-   **Base URL:** `https://kqgbftwsodpttpqgqnbh.supabase.co/rest/v1`
-   **API Key:** `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtxZ2JmdHdzb2RwdHRwcWdxbmJoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDU5ODk5OTksImV4cCI6MjA2MTU2NTk5OX0.rwJSY4bJaNdB8jDn3YJJu_gKtznzm-dUKQb4OvRtP6c`
-   **Endpoints:** `/customers`, `/activities`, `/visits`

## Key Expectations Addressed

### Architecture & Scalability
-   **Separation of Concerns:** Achieved through a clear Presentation-Domain-Data layered architecture.
-   **Modular Design:** Features are organized into their own directories (`features/visits`, `features/customers`, `features/activities`), promoting modularity.
-   **Dependency Injection:** `get_it` is used for managing dependencies, making components easily swappable and testable.
-   **Maintainability & Testability:** Each layer is independently testable, reducing coupling.

### State & Navigation
-   **State Management:** `flutter_bloc` (specifically `Cubit`) is chosen for robust and predictable state management. It clearly separates UI state from business logic and handles asynchronous operations gracefully.
-   **Global vs. Local State:** `VisitCubit` manages global state related to visits, customers, and activities, while individual widgets manage their local UI state (e.g., text field controllers).
-   **Navigation System:** `go_router` is used for declarative and type-safe routing, providing a flexible way to handle navigation across multiple screens.

### Data & API Layer
-   **Structured Data Layer:** Consists of `RemoteDataSources`, `Repositories`, `Models`, and `Entities`.
-   **API Client:** `Dio` is used as the HTTP client, configured with the API key in headers.
-   **Error Handling:** Custom `Failure` and `Exception` classes are used, and repositories map network exceptions to domain failures, ensuring consistent error propagation.
-   **Loading Indicators:** UI displays `CircularProgressIndicator` during API calls.

### User Experience
-   **Intuitive UI:** Clear layout for listing and adding visits.
-   **Loading/Error States:** Users are informed about data loading and any encountered errors.
-   **Search and Filter:** Provided functionality to easily find specific visits.
-   **Activity Mapping:** Activities are displayed by their `description` rather than just IDs for better readability.

### Offline Handling (Optional)
-   *Not fully implemented in this version to meet the initial time constraints.*
-   **Design for Plug-in:** The data layer is designed to easily integrate a `LocalDataSource` (e.g., using `Hive` or `shared_preferences`). The `VisitRepositoryImpl` already includes comments showing where a local data source would be integrated to serve cached data or store pending offline writes.

### Testing (Optional)
-   *Unit tests for core logic (e.g., Use Cases, Cubits) are demonstrated.*
-   **Unit Tests:** Example unit tests are provided for `GetAllVisits` use case, showcasing how to test business logic independently using `mockito`.
-   Further tests would cover other use cases, repositories, and model conversions.
-   Widget tests would be added for UI components to ensure correct rendering and interaction.

### CI/CD (Optional Nice-to-Have)
-   *A basic GitHub Actions workflow is provided.*
-   **GitHub Actions:** A simple CI workflow is set up to run `flutter analyze` and `flutter test` on push and pull requests, ensuring code quality and test coverage.

## Assumptions, Trade-offs, and Limitations

### Assumptions:
-   The `activities_done` field in the `/visits` API is a JSON array of strings, where each string represents an `id` that can be parsed into an integer.
-   Supabase returns the inserted row in the `POST /visits` response when `select='*'` is used as a query parameter.
-   The application does not require user authentication beyond the provided API key.

### Trade-offs:
-   **Simplicity vs. Full Feature Set:** Focus was placed on a robust core architecture rather than implementing every possible CRUD operation (e.g., `update visit`, `delete visit`) or complex filtering. These can be easily extended.
-   **Offline Handling:** Prioritized a solid online architecture first. Offline support is designed to be easily integrated but not fully implemented due to time constraints.
-   **Advanced UI/UX:** While usability was a priority, highly polished animations or custom UI elements were not the focus.

### Limitations:
-   No pagination for lists: Assumes a manageable number of visits, customers, and activities. For larger datasets, pagination would be crucial.
-   No real-time updates: Data is fetched on demand or on refresh.
-   Basic search: The search functionality is a simple `contains` check on specific fields and does not include full-text search capabilities.
-   No image or file uploads: Not part of the problem description.
-   Error messages are generic; a more user-friendly error mapping could be implemented for different API error codes.

## Future Improvements

-   Implement full offline support with robust syncing mechanisms (e.g., using a local database like Hive).
-   Add user authentication and user-specific data.
-   Implement pagination for fetching large lists of data.
-   Enhance search and filtering capabilities (e.g., date range filtering, more advanced text search).
-   Add edit and delete functionalities for visits.
-   Implement push notifications for reminders or updates.
-   Improve UI/UX with more polished designs, animations, and user feedback mechanisms.
-   Integrate a mapping service for `location` data.