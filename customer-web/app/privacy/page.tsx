import type { Metadata } from "next";

import { LegalPage } from "@/components/legal-page";

export const metadata: Metadata = { title: "Privacy policy" };

export default function PrivacyPage() {
  return (
    <LegalPage title="Privacy policy" updated="7 August 2026">
      <section>
        <h2>What we collect</h2>
        <p>We collect the account, contact, delivery address, order and support information needed to provide the service. If you allow location access, it is used to select a delivery point and calculate availability and fees.</p>
      </section>
      <section>
        <h2>How we use information</h2>
        <ul>
          <li>To create, prepare, deliver and support your orders.</li>
          <li>To secure accounts, prevent misuse and meet legal obligations.</li>
          <li>To understand service performance using privacy-conscious analytics when configured.</li>
        </ul>
      </section>
      <section>
        <h2>Payments and service providers</h2>
        <p>Online payments are completed on the selected payment provider&apos;s secure page. We receive the payment result and transaction reference, not your payment PIN. Delivery, messaging, hosting and monitoring providers may process only the information required for their service.</p>
      </section>
      <section>
        <h2>Retention and your choices</h2>
        <p>We keep information only as long as needed for orders, support, security and applicable accounting requirements. You can ask support to correct or delete eligible account information. Browser Do Not Track is respected by the optional web analytics integration.</p>
      </section>
      <section>
        <h2>Security and questions</h2>
        <p>We use access controls, encrypted transport and protected browser sessions. No online service can promise absolute security. Contact support for privacy questions or account requests.</p>
      </section>
    </LegalPage>
  );
}
