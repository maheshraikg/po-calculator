# Publishing PO Calculator on Google Play – step by step

Everything Play Console asks for is ready in this repository. Google's forms
change from time to time; if a screen looks different, pick the answer that
matches the meaning below.

## What is ready

| Play Console asks for | Where it is |
|---|---|
| App bundle (.aab) | GitHub → **Actions** → latest **Release** run → artifact **po-calculator-play-bundle** → `po_calculator.aab` |
| App name (≤30) | `store/listing/en-IN/title.txt` – **PO Calculator: Post Office** |
| Short description (≤80) | `store/listing/en-IN/short_description.txt` |
| Full description (≤4000) | `store/listing/en-IN/full_description.txt` |
| Kannada listing | `store/listing/kn-IN/` (add language **Kannada – kn-IN**) |
| App icon 512×512 | `store/icon_512.png` |
| Feature graphic 1024×500 | `store/feature_graphic.png` |
| Phone screenshots (2–8) | `store/screenshots/en/1_home.png` … `8_languages.png` (1080×1920) |
| Privacy policy URL | https://github.com/maheshraikg/po-calculator/blob/main/PRIVACY.md |
| Contact e-mail | maheshraikg@gmail.com |
| Upload key | `upload.jks` in your private Google Drive folder (SHA-256 `7B:26:4D:90:…:94:0F:C1:63`) |

## 1. Create the developer account (once)

1. Open https://play.google.com/console/signup with **maheshraikg@gmail.com**.
2. Choose **Personal** account (or Organisation if you publish for a company).
3. Pay the one-time **US $25** fee and finish identity verification (PAN /
   Aadhaar / address as Google asks). Verification can take a few days.

> New personal accounts must run a **closed test with at least 12 testers for
> 14 days in a row** before Google allows a production (public) release.
> Plan this: collect 12+ Gmail addresses (friends, colleagues, post office
> staff) who will install the test version and keep it for 14 days.

## 2. Create the app

**Home → Create app**
- App name: `PO Calculator: Post Office`
- Default language: **English (India) – en-IN**
- App or game: **App** · Free or paid: **Free**
- Tick the declarations → **Create app**

## 3. App content (left menu → Policy → App content)

| Section | Answer |
|---|---|
| Privacy policy | `https://github.com/maheshraikg/po-calculator/blob/main/PRIVACY.md` |
| App access | **All functionality is available without special access** |
| Ads | **No, my app does not contain ads** |
| Content rating | Start questionnaire → e-mail maheshraikg@gmail.com → category **All other app types** (utility/reference) → answer **No** to every question (no violence, no user content, no gambling, no sharing of location, no purchases) → expected rating **Everyone / 3+** |
| Target audience | **18 and over** only (keeps it out of the Families programme) |
| News app | **No** |
| Data safety | Does your app collect or share any of the required user data types? **No**. (Nothing leaves the phone; backup and e-mail are started by the user through other apps.) |
| Government apps | **No** – it is an independent app, not made for or by a government body |
| Financial features | It is a calculator only: no loans, payments, banking or investment services. Choose the option that says the app **does not provide** these financial features (if a “calculator/information only” option exists, choose that) |
| Health apps | **No** |
| Advertising ID | **No** (the app does not use it) |

## 4. Store listing (Grow users → Store presence → Main store listing)

1. App name, short and full description: paste from `store/listing/en-IN/`.
2. App icon: upload `store/icon_512.png`.
3. Feature graphic: upload `store/feature_graphic.png`.
4. Phone screenshots: upload all 8 from `store/screenshots/en/`.
5. **Store settings**: category **Finance**; contact e-mail
   maheshraikg@gmail.com; tags: *finance, calculator*.
6. Optional: **Manage translations → Add Kannada (kn-IN)** and paste
   `store/listing/kn-IN/`.

## 5. Closed test (needed before production for new personal accounts)

1. **Test and release → Testing → Closed testing → Create track** (or use
   "Alpha").
2. **Testers**: create an e-mail list with your 12+ testers → copy the
   **opt-in link** and send it to them.
3. **Create new release**:
   - App signing: accept **Use Google-generated key** (Play App Signing).
     Google keeps the final signing key; you keep the upload key.
   - Upload `po_calculator.aab` (download it from GitHub Actions, unzip).
   - Release notes: e.g. *First release: offline Post Office calculator in 11 languages.*
   - **Save → Review release → Start rollout to Closed testing**.
4. Testers open the opt-in link, accept, install from Play, and keep the app
   for **14 days**. Ask them to open it a few times.

## 6. Production

1. After 14 days: **Dashboard → Apply for production** and answer the short
   questions about your test.
2. When approved: **Production → Create new release → Add from library**
   (the same .aab) or upload a newer one → **Countries: India** (or all) →
   **Review → Start rollout to Production**.
3. Google's review usually takes a few days. Then the app is public.

## Every later update

1. Bump `version:` in `pubspec.yaml` (e.g. `1.6.0+20`) and push to `main`.
2. Download the new `po_calculator.aab` from that run's **po-calculator-play-bundle**.
3. Play Console → Production (or a test track) → **Create new release** →
   upload → roll out.

## Things Google may check

- **Name and India Post**: the app is independent and says so in the
  description and in the app. Do not add India Post logos or the word
  "official". If Google asks, explain it is a private calculator that only
  links to public forms on indiapost.gov.in and nsiindia.gov.in.
- **Ads later**: if you add ads, update the Ads answer, the Data safety form,
  the privacy policy, and the app will need internet permission.
