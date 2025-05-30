# Firestore Setup Guide for Atoms Innovation Hub

## Step 1: Enable Authentication

1. Go to Firebase Console → Authentication
2. Click "Get Started"
3. Go to "Sign-in method" tab
4. Enable these providers:

### Email/Password:
- Click "Email/Password"
- Toggle "Enable" to ON
- Click "Save"

### Google:
- Click "Google"
- Toggle "Enable" to ON
- Enter your support email
- Click "Save"

## Step 2: Create Firestore Database

1. Go to Firebase Console → Firestore Database
2. Click "Create database"
3. Choose "Start in test mode"
4. Select your preferred location
5. Click "Enable"

## Step 3: Create Collections and Sample Data

### Collection 1: "users"
1. Click "Start collection"
2. Collection ID: `users`
3. Document ID: `test_user_001`
4. Add these fields:

```
email: "admin@atomshub.com" (string)
name: "Admin User" (string)
photoUrl: "" (string)
isAdmin: true (boolean)
createdAt: [Click timestamp icon - select current date/time]
lastLogin: [Click timestamp icon - select current date/time]
```

### Collection 2: "applications"
1. Click "Start collection"
2. Collection ID: `applications`
3. Document ID: `app_001`
4. Add these fields:

```
name: "Task Manager Pro" (string)
description: "A powerful task management application with real-time collaboration features" (string)
imageUrl: "" (string)
downloadUrl: "https://github.com/example/task-manager/releases" (string)
features: ["Real-time collaboration", "Task scheduling", "Progress tracking", "Team management"] (array)
version: "2.1.0" (string)
downloadCount: 1250 (number)
releaseDate: [Click timestamp icon - select a date 3 months ago]
lastUpdated: [Click timestamp icon - select current date/time]
```

### Collection 3: "blog_posts"
1. Click "Start collection"
2. Collection ID: `blog_posts`
3. Document ID: `post_001`
4. Add these fields:

```
title: "Welcome to Atom's Innovation Hub" (string)
content: "# Welcome to Our Innovation Hub\n\nWe're excited to share our latest projects and insights with you.\n\n## What You'll Find Here\n\n- **Cutting-edge Applications**: Discover our latest software solutions\n- **Technical Insights**: Deep dives into development processes\n- **Innovation Stories**: Behind-the-scenes looks at our projects\n\n## Getting Started\n\nExplore our applications section to see what we've been building, or check out our latest blog posts for technical insights and project updates.\n\n*Happy exploring!*" (string)
imageUrl: "" (string)
authorId: "test_user_001" (string)
authorName: "Admin User" (string)
tags: ["welcome", "introduction", "innovation"] (array)
viewCount: 42 (number)
commentCount: 0 (number)
comments: [] (array)
createdAt: [Click timestamp icon - select current date/time]
updatedAt: [Click timestamp icon - select current date/time]
```

## Step 4: Set Security Rules (Optional for Development)

Go to Firestore Database → Rules and replace with:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read: true;
      allow write: if request.auth != null;
    }
  }
}
```

## Step 5: Set Storage Rules

Go to Storage → Rules and replace with:

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read: true;
      allow write: if request.auth != null;
    }
  }
}
```

## Verification Steps

After setup, you should see:
- 3 collections in Firestore: users, applications, blog_posts
- Each collection with 1 sample document
- Authentication methods enabled
- Storage configured

Your app should now be able to:
- Display the sample app in the Apps section
- Show the welcome blog post in the Blog section
- Allow user registration and login
- Show admin dashboard for the admin user 