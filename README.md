# ChatMate

## Overview 

**ChatMate** is a dynamic cross-platform mobile app designed for seamless real-time communication. Built with Flutter and Dart, and powered by Firebase, it offers features such as text messaging, voice notes, image sharing, online status, unread message count, user blocking, and chat clearing. ChatMate ensures a smooth and engaging chatting experience, suitable for both personal and group interactions.

## Table of Contents

- [Features](#features)
- [Technologies Used](#technologies-used)
- [Installation](#installation)
- [Usage](#usage)
- [Screenshots](#screenshots)

## Features

- **Real-time Messaging**: Chat with friends in real-time using text messages.
- **Voice Notes**: Record and send voice notes seamlessly within the chat.
- **Image Sharing**: Share images with friends by picking from the gallery.
- **Online Status**: View the online status of your friends.
- **Unread Message Count**: Keep track of unread messages for each conversation.
- **User Blocking**: Block users to prevent them from sending you messages.
- **Chat Clearing**: Clear chat history with a specific user.
- **Profile Viewing**: View the profile information of your friends.

## Technologies Used

### Frontend

- **Flutter**: For building the cross-platform mobile application.
- **Dart**: The programming language used with Flutter.
- **Firebase Authentication**: For user authentication and authorization.
- **Firebase Firestore**: For real-time database needs.
- **Firebase Storage**: For storing images and voice notes.
- **Flutter Packages**:
  - `provider`: For state management.
  - `image_picker`: For selecting images from the gallery or camera.
  - `flutter_sound`: For recording and playing voice notes.
  - `permission_handler`: For handling permissions.
  - `path_provider`: For accessing the device's file system.
  - `firebase_core`: For initializing Firebase in the Flutter app.
  - `cloud_firestore`: For interacting with Firestore.
  - `firebase_storage`: For uploading and downloading files from Firebase Storage.

### Backend

- **Firebase Cloud Functions**: For serverless backend logic.
- **Firebase Firestore**: For storing user data and messages.
- **Firebase Storage**: For storing media files.

### Other Tools and Technologies

- **GitHub Actions**: For continuous integration and deployment.
- **Dart Code Metrics**: For code quality checks.
- **Prettier**: For code formatting.

## Installation

To get a local copy up and running, follow these simple steps:

### Prerequisites

- [Flutter](https://flutter.dev/docs/get-started/install): Ensure you have Flutter installed on your machine.
- [Firebase CLI](https://firebase.google.com/docs/cli): For deploying Cloud Functions and other Firebase resources.

### Setup

1. Clone the repository:

```bash
git clone https://github.com/your-username/ChatMate.git
cd ChatMate
```

2. Install dependencies:

```bash
flutter pub get
```

3. Setup Firebase:

- Create a Firebase project in the [Firebase Console](https://console.firebase.google.com/).
- Add your Android and iOS apps to the Firebase project.
- Download the `google-services.json` file for Android and `GoogleService-Info.plist` for iOS, and place them in the respective directories:
  - `android/app`
  - `ios/Runner`

4. Initialize Firebase in your project:

```bash
firebase init
```

Follow the prompts to set up Firestore, Authentication, and Cloud Functions.

## Usage

1. Download the released APK.
2. Log in or register to start using the chat features.
3. Send text messages, images, and voice notes to your friends.
4. View online status and unread message count for each conversation.
5. Clear chat history, block users, and view friend profiles from the chat screen.

## Screenshots

<div style="display: flex; flex-wrap: wrap; justify-content: space-evenly;">
  <img src="https://github.com/DevAnuragT/ChatMate-Flutter/assets/97083108/bb951a77-23e2-4896-af25-039ec251290f" width="30%" style="margin: 10px;">
  <img src="https://github.com/DevAnuragT/ChatMate-Flutter/assets/97083108/586dab0a-3a88-41ae-aec1-06376e6ebf1d" width="30%" style="margin: 10px;">
  <img src="https://github.com/DevAnuragT/ChatMate-Flutter/assets/97083108/06335082-595f-459e-8c99-44f342365b75" width="30%" style="margin: 10px;">
  <img src="https://github.com/DevAnuragT/ChatMate-Flutter/assets/97083108/9b040330-3a3e-4ede-8b51-4b883a9de59c" width="30%" style="margin: 10px;">
  <img src="https://github.com/DevAnuragT/ChatMate-Flutter/assets/97083108/1b35c996-670c-4f27-a266-99703c4b85bb" width="30%" style="margin: 10px;">
  <img src="https://github.com/DevAnuragT/ChatMate-Flutter/assets/97083108/85cfd988-31a9-446b-befa-202415f30355" width="30%" style="margin: 10px;">
  <img src="https://github.com/DevAnuragT/ChatMate-Flutter/assets/97083108/0453f04d-64a3-4a03-b57d-838b3e5fcd34" width="30%" style="margin: 10px;">
  
</div>

---
