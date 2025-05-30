# Firebase Storage CORS Fix Instructions

## Problem
The profile pictures are uploading successfully to Firebase Storage, but they're not displaying due to CORS (Cross-Origin Resource Sharing) restrictions.

## Solution
You need to configure CORS for your Firebase Storage bucket. Here are the steps:

### Method 1: Using Google Cloud Console (Recommended)

1. **Go to Google Cloud Console**
   - Visit: https://console.cloud.google.com/
   - Select your project: `atoms-innovation-hub-5fbd0`

2. **Navigate to Cloud Storage**
   - In the left menu, go to "Storage" > "Cloud Storage" > "Buckets"
   - Find your bucket: `atoms-innovation-hub-5fbd0.firebasestorage.app`

3. **Configure CORS**
   - Click on your bucket name
   - Go to the "Permissions" tab
   - Click "Edit CORS configuration"
   - Add this CORS configuration:

```json
[
  {
    "origin": ["*"],
    "method": ["GET", "HEAD", "PUT", "POST", "DELETE"],
    "maxAgeSeconds": 3600,
    "responseHeader": ["Content-Type", "Access-Control-Allow-Origin", "x-goog-resumable"]
  }
]
```

### Method 2: Using Firebase CLI (Alternative)

1. **Install Firebase CLI** (if not already installed)
```bash
npm install -g firebase-tools
```

2. **Login to Firebase**
```bash
firebase login
```

3. **Create a CORS configuration file**
Create a file named `cors.json` with this content:
```json
[
  {
    "origin": ["*"],
    "method": ["GET", "HEAD", "PUT", "POST", "DELETE"],
    "maxAgeSeconds": 3600,
    "responseHeader": ["Content-Type", "Access-Control-Allow-Origin", "x-goog-resumable"]
  }
]
```

4. **Apply CORS configuration**
```bash
gsutil cors set cors.json gs://atoms-innovation-hub-5fbd0.firebasestorage.app
```

### Method 3: More Restrictive CORS (Production Recommended)

For production, use a more restrictive CORS policy:

```json
[
  {
    "origin": ["http://localhost:8081", "https://your-domain.com"],
    "method": ["GET", "HEAD"],
    "maxAgeSeconds": 3600,
    "responseHeader": ["Content-Type"]
  }
]
```

## After Applying CORS

1. **Clear browser cache** or open an incognito window
2. **Refresh your app** at http://localhost:8081
3. **Try uploading a profile picture again**
4. **The image should now display correctly**

## Verification

After applying CORS, you should see:
- ✅ Profile pictures display immediately after upload
- ✅ No more "HTTP request failed, statusCode: 0" errors
- ✅ Images load properly from Firebase Storage URLs

## Note

The CORS configuration may take a few minutes to propagate. If it doesn't work immediately, wait 5-10 minutes and try again. 