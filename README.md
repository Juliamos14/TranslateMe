# Project 6 - *TranslateMe*

Submitted by: **Julian Lesesne**

**TranslateMe** is a SwiftUI app that translates words, phrases, and sentences using the MyMemory translation API. The user types text in the top field, picks the languages to translate from and to, and taps Translate to see the result in the bottom field. Every translation is saved to a Firebase Firestore database, so the history stays on the screen even after the app is closed, and the user can erase the whole history at any time.

Time spent: **4** hours spent in total

## Required Features

The following **required** functionality is completed:

- [x] Users open the app to a TranslationMe home page with a place to enter a word, phrase or sentence, a button to translate, and another field that should initially be empty
- [x] When users tap translate, the word written in the upper field translates in the lower field. The requirement is only that you can translate from one language to another.
- [x] A history of translations can be stored (in a scroll view in the same screen, or a new screen)
- [x] The history of translations can be erased
 
The following **optional** features are implemented:

- [x] Add a variety of choices for the languages
- [x] Add UI flair

The following **additional** features are implemented:

- [x] A swap button switches the "from" and "to" languages, and moves the translation up so it can be translated back
- [x] The translation can be copied with one tap
- [x] Tapping a history item puts that text and its languages back into the translator
- [x] Single history items can be removed with a swipe, and erasing everything asks for confirmation first
- [x] History updates live from Firestore, newest first, and stays after the app is closed
- [x] A loading indicator shows while translating, and clear messages appear for empty text, no internet, or text that's too long

## Video Walkthrough

Here's a walkthrough of implemented user stories:

<div>
    <a href="https://www.loom.com/share/<VIDEO_ID>">
      <p>TranslateMe - Video Walkthrough (click to watch on Loom)</p>
    </a>
    <a href="https://www.loom.com/share/<VIDEO_ID>">
      <img style="max-width:300px;" src="https://www.loom.com/v1/videos/<VIDEO_ID>/thumbnail.gif">
    </a>
</div>

## Notes

Challenges encountered while building the app:

- **Setting up Firebase.** The app needs the Firebase iOS SDK added through Swift Package Manager, a `GoogleService-Info.plist` file from the Firebase console added to the project, and a Firestore database created in test mode so the app can read and write without signing in.
- **Building the translation request.** MyMemory expects the languages as a pair like `en|es`, and the text has to be URL-encoded so spaces and special characters reach the API correctly.
- **Reading MyMemory's response.** The API can return a successful response that's actually a warning (for example, when the free daily limit is reached), so the app checks the response status before treating the text as a translation. Some results also come back with HTML codes for symbols, which the app converts back to normal characters.
- **Text length.** MyMemory only accepts up to 500 bytes per request, so the app checks the length first and shows a message instead of sending a request that would fail.
- **Live history and erasing it.** The history uses a Firestore listener, so new translations appear as soon as they're saved. Erasing the history deletes every document in a single batch, so the list clears all at once instead of one row at a time.

## License

    Copyright 2026 Julian Lesesne

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
