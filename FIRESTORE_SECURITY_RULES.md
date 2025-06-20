# 🔒 Firestore Security Rules Configuration

## **Required Security Rules**

Navigate to your **Firebase Console** → **Firestore Database** → **Rules** and paste the following:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /markers/{doc} {
      allow read, write: if true;
    }
  }
}
```

## **Important Notes**

⚠️ **The above rules allow unrestricted access and are suitable for development only**

## **Production-Ready Rules (Recommended)**

For production apps, implement authentication-based rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Require authentication for all marker operations
    match /markers/{doc} {
      allow read, write: if request.auth != null;
    }
    
    // Optional: Restrict based on user ownership
    match /markers/{doc} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
                   resource.data.salesman_name == request.auth.displayName;
    }
  }
}
```

## **Setting Up the Rules**

1. **Go to Firebase Console**: https://console.firebase.google.com/
2. **Select your project**
3. **Navigate to Firestore Database**
4. **Click on "Rules" tab**
5. **Replace the default rules** with the rules above
6. **Click "Publish"**

## **Testing the Rules**

1. **Build and run your app**
2. **Try adding a marker** - should work without errors
3. **Check Firestore console** - you should see documents in the `markers` collection
4. **Test real-time updates** - changes should appear instantly

## **Troubleshooting**

### "Permission denied" errors:
- Check that the rules are published
- Verify the collection name is "markers"
- Ensure your app is using the correct Firebase project

### Rules not taking effect:
- Wait a few minutes after publishing
- Clear app data and restart
- Check Firebase console for rule validation errors

---

**✅ Once these rules are set, your Firebase integration will be fully functional!** 