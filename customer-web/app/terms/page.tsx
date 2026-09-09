import type { Metadata } from "next";

import { LegalPage } from "@/components/legal-page";

export const metadata: Metadata = { title: "Terms of service" };

export default function TermsPage() {
  return (
    <LegalPage title="Terms of service" updated="7 August 2026">
      <section>
        <h2>Using Wasabi</h2>
        <p>You must provide accurate contact and delivery information and use the service lawfully. Keep your sign-in and delivery confirmation codes private.</p>
      </section>
      <section>
        <h2>Orders, availability and pricing</h2>
        <p>An order is subject to restaurant availability, delivery coverage and acceptance. The checkout total shows the applicable item prices, discounts, packaging, tax and delivery fee before placement. We will explain any order we cannot fulfil.</p>
      </section>
      <section>
        <h2>Payment, cancellation and refunds</h2>
        <p>Cash orders are paid on receipt or pickup. Online orders are sent to the kitchen only after payment confirmation. Cancellation availability depends on the order stage. Refund requests are reviewed against the order and payment record; approved online refunds return through the applicable payment process.</p>
      </section>
      <section>
        <h2>Delivery</h2>
        <p>Estimated times are not guarantees and can change with preparation, traffic, weather or rider availability. Check the order before sharing a delivery confirmation code.</p>
      </section>
      <section>
        <h2>Problems and changes</h2>
        <p>Report incorrect, missing or damaged items through support as soon as practical. We may update these terms as the service changes; the current version and update date will remain available here.</p>
      </section>
    </LegalPage>
  );
}
