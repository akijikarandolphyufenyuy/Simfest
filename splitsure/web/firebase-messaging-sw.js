// firebase-messaging-sw.js
// Place this file in the /web directory.
// Replace the firebaseConfig values with your actual Firebase project config.

importScripts("https://www.gstatic.com/firebasejs/10.13.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.13.0/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey:            "AIzaSyAxKZsZi5f4tq_urvEN9PcL__2FoX_8OjY",
  authDomain:        "splitsure-e31bd.firebaseapp.com",
  projectId:         "splitsure-e31bd",
  storageBucket:     "splitsure-e31bd.firebasestorage.app",
  messagingSenderId: "130930853529",
  appId:             "1:130930853529:web:5fbc4e88ce5e065a069a08",
});

const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage((payload) => {
  console.log("[firebase-messaging-sw.js] Background message:", payload);
  const { title, body } = payload.notification ?? {};
  return self.registration.showNotification(title ?? "SplitSure", {
    body: body ?? "",
    icon: "/icons/Icon-192.png",
    badge: "/icons/Icon-192.png",
  });
});
