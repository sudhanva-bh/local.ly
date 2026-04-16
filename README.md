# locally

## Project Description

locally is a comprehensive Flutter-based mobile application designed to bridge the gap between wholesale sellers, retail sellers, and consumers. The platform facilitates a multi-layered marketplace where wholesalers can list products for retailers, and retailers, in turn, can manage their inventory and sell directly to consumers. The application leverages a modern tech stack to provide real-time updates, secure authentication, and location-based services with a clear separation between frontend and backend responsibilities.

## Key Features

* **Multi-User Ecosystem**: Dedicated interfaces and workflows for Wholesale Sellers, Retail Sellers, and Consumers.
* **Real-time Communication**: Integrated chat functionality allowing direct interaction between buyers and sellers.
* **Inventory Management**: Tools for sellers to create, edit, and track their product listings.
* **Order Tracking**: Comprehensive order management system with status updates and history for all user types.
* **Location Services**: Interactive maps for shop discovery and delivery address selection.
* **Document Generation**: Automated invoice generation and printing capabilities for completed transactions.
* **Barcode/QR Integration**: Support for mobile scanning and QR code generation for streamlined operations.

## Technology Stack

* **Framework**: Flutter (SDK ^3.8.1)
* **State Management**: Flutter Riverpod
* **Backend as a Service**: Supabase (Database, Auth, and Storage)
* **Cloud Messaging**: Firebase Core and Firebase Messaging for notifications
* **Mapping**: Flutter Map with OpenStreetMap integration
* **Functional Programming**: Fpdart

## Project Structure

The source code is organized into a feature-first architecture:

* **lib/common**: Shared models, providers, services, and themes used across the entire application.
* **lib/features/auth**: Authentication logic including sign-in and registration forms.
* **lib/features/consumer**: Features specific to the end-user, including the shopping cart, checkout, and order viewing.
* **lib/features/retail_seller**: Interface for retail business owners to manage products and fulfill consumer orders.
* **lib/features/wholesale_seller**: Interface for wholesalers to manage bulk product listings.
* **lib/features/chat**: Messaging infrastructure for real-time communication.

## Architecture Overview

The application follows a client-server architecture:

- **Frontend (Flutter)**  
  Handles UI rendering, user interactions, and client-side state management using Riverpod.

- **Backend (Supabase + Firebase)**  
  Manages authentication, database operations, storage, and real-time updates.

- **Communication**  
  The frontend interacts with backend services via API calls and real-time subscriptions.

- **Feature-Based Structure**  
  Each feature module encapsulates its UI, logic, and state handling for scalability and maintainability.

## Frontend Responsibilities

The frontend layer of the application includes:

- Building UI components and screens using Flutter
- Managing application state with Riverpod
- Handling user interactions and navigation flows
- Integrating backend APIs and rendering dynamic data
- Managing asynchronous data loading and error handling
- Ensuring responsive and consistent UI across different features

## Getting Started

### Prerequisites

* Flutter SDK ^3.8.1+
* Dart SDK matching the Flutter requirement
* A Supabase project for backend services
* A Firebase project for push notifications

### Installation

1. Clone the repository.
2. Create a .env file in the root directory with your specific configuration keys.
3. Run the following command to install dependencies:
```bash
flutter pub get

```


4. Generate necessary code using build_runner:
```bash
dart run build_runner build

```


5. Launch the application:
```bash
flutter run

```



## Assets

The project utilizes several asset categories defined in the configuration:

* **assets/images/**: General application imagery and icons.
* **assets/setup/**: Assets related to the initial user onboarding and setup process.
* **assets/splash/**: Visuals for the application launch screen.

## Notes
Due to the development workflow used during the project, commits were pushed from a single system. This [document](https://github.com/sudhanva-bh/local.ly/blob/main/docs/contribution.md) reflects our actual development contributions to the project.