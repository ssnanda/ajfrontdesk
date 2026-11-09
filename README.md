# AJ Front Desk

Visitor check-in kiosk for sites running AJ Core RA. The home screen has two buttons: Tour (a prospect leaves their details)
and Check In, a short conversation: who they are here to see (a staff member or a Suite Client), their phone number (a
returning guest's name is filled in), their name, and whether they have an appointment. AJ Core RA logs the visit and gives
it a Guest ID (G-YYYYMMDD-NNN); the host is texted from AJOps (Guest Log > Notify client).

- First launch: enter the site URL, the device key and a staff PIN (long-press the welcome title later to change them).
- Device keys are created in AJ Core > Client Portal > Reception. A key only unlocks the reception endpoints.
- Bundle id `com.itspector.frontdesk`. Pair with iOS Guided Access to lock the iPad to this app.
- Started from the old NAC Insiders `upos-reception-ipad` app.
