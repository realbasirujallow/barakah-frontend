export const metadata = {
  title: 'Privacy Policy — Barakah',
  description: 'How Barakah collects, uses, and protects your personal and financial data.',
};

const LAST_UPDATED = 'March 4, 2026';
const CONTACT_EMAIL = 'support@trybarakah.com';
const APP_NAME = 'Barakah';
const COMPANY = 'Barakah';
const SITE = 'https://trybarakah.com';

export default function PrivacyPage() {
  return (
    <div className="min-h-screen bg-white">
      {/* Header */}
      <header className="bg-emerald-700 text-white py-12 px-4">
        <div className="max-w-3xl mx-auto">
          <div className="flex items-center gap-3 mb-4">
            <div className="w-10 h-10 bg-white/20 rounded-xl flex items-center justify-center">
              <span className="text-white text-lg font-bold">ب</span>
            </div>
            <span className="text-white/80 text-sm font-medium tracking-wide uppercase">Barakah</span>
          </div>
          <h1 className="text-3xl font-bold">Privacy Policy</h1>
          <p className="text-emerald-200 mt-2 text-sm">Last updated: {LAST_UPDATED}</p>
        </div>
      </header>

      {/* Body */}
      <main className="prose-legal max-w-3xl mx-auto px-4 py-12 text-gray-700 text-sm leading-relaxed">

        <section className="mb-8 p-5 bg-emerald-50 border border-emerald-100 rounded-xl">
          <p>
            Your privacy matters to us. This Privacy Policy explains how {APP_NAME} (&ldquo;we&rdquo;, &ldquo;us&rdquo;, or &ldquo;our&rdquo;)
            collects, uses, shares, and protects your information when you use our mobile application and
            website (collectively, the &ldquo;Service&rdquo;). Please read it carefully before using our Service.
          </p>
        </section>

        <Section title="1. Information We Collect">
          <SubSection title="1.1 Account Information">
            <p>When you create a Barakah account we collect:</p>
            <ul>
              <li><strong>Full name</strong> — used to personalise your experience and email communications.</li>
              <li><strong>Email address</strong> — used for account authentication, verification, and transactional notifications.</li>
              <li><strong>Password</strong> — stored as a one-way cryptographic hash (bcrypt). We never store or transmit your plaintext password.</li>
            </ul>
          </SubSection>

          <SubSection title="1.2 Financial Data You Enter">
            <p>The Service allows you to record personal financial information, including:</p>
            <ul>
              <li>Income and expense transactions</li>
              <li>Monthly budgets and spending categories</li>
              <li>Bills and recurring payment schedules</li>
              <li>Debt accounts, balances, and repayment plans</li>
              <li>Investment assets and portfolio values</li>
              <li>Zakat assets, hawl start dates, and zakat payment history</li>
              <li>Sadaqah (charitable giving) records</li>
              <li>Waqf (endowment) contributions</li>
              <li>Wasiyyah (will) beneficiary allocations</li>
              <li>Shared household finance group memberships</li>
            </ul>
            <p>This data is stored securely on our servers and is used solely to provide the Service to you.</p>
          </SubSection>

          <SubSection title="1.3 Usage and Device Data">
            <p>We may automatically collect:</p>
            <ul>
              <li>Device type, operating system version, and app version</li>
              <li>IP address and approximate geographic region (country / city level)</li>
              <li>App usage events (screens viewed, features used) via our analytics provider (PostHog)</li>
              <li>Crash reports and error logs to help us identify and fix bugs</li>
            </ul>
            <p>
              We do <strong>not</strong> use advertising identifiers (IDFA / GAID) and we do <strong>not</strong> build
              advertising profiles.
            </p>
          </SubSection>

          <SubSection title="1.4 Information We Do Not Collect">
            <ul>
              <li>Bank account or card numbers — we have no direct bank connection feature.</li>
              <li>Government identification numbers (SSN, national ID, passport).</li>
              <li>Biometric data (fingerprint, face ID) — authentication is handled entirely by your device&apos;s operating system.</li>
            </ul>
          </SubSection>
        </Section>

        <Section title="2. How We Use Your Information">
          <p>We use the information we collect to:</p>
          <ol>
            <li>Create and manage your account, and authenticate your identity.</li>
            <li>Provide, maintain, and improve the features of the Service.</li>
            <li>Send transactional emails — account verification, password resets, bill reminders, hawl completion alerts, and zakat due notices.</li>
            <li>Calculate and display zakat obligations, halal investment scores, and riba risk assessments based on data you provide.</li>
            <li>Detect and diagnose technical errors and security incidents.</li>
            <li>Comply with legal obligations and enforce our Terms of Service.</li>
          </ol>
          <p>
            We do <strong>not</strong> sell, rent, or trade your personal or financial data to third parties for marketing purposes.
          </p>
        </Section>

        <Section title="3. Legal Basis for Processing (GDPR)">
          <p>If you are in the European Economic Area (EEA) or United Kingdom, we process your data under the following legal bases:</p>
          <ul>
            <li><strong>Contract performance</strong> — processing necessary to deliver the Service you requested.</li>
            <li><strong>Legitimate interests</strong> — analytics and security monitoring, balanced against your rights.</li>
            <li><strong>Legal obligation</strong> — where required by applicable law.</li>
            <li><strong>Consent</strong> — for optional communications such as product updates (you may withdraw at any time).</li>
          </ul>
        </Section>

        <Section title="4. Sharing Your Information">
          <p>We only share your information with third parties in the following circumstances:</p>

          <SubSection title="4.1 Service Providers">
            <p>We work with trusted third-party companies that process data on our behalf:</p>
            <ul>
              <li><strong>Railway (Render Networks Inc.)</strong> — cloud hosting of our backend servers and database.</li>
              <li><strong>Resend</strong> — transactional email delivery.</li>
              <li><strong>PostHog</strong> — product analytics (anonymised event data only).</li>
            </ul>
            <p>These providers are contractually bound to use your data only to provide services to us and may not use it for their own purposes.</p>
          </SubSection>

          <SubSection title="4.2 Legal Requirements">
            <p>
              We may disclose your information if required to do so by law, court order, or valid government request, or
              when we believe disclosure is necessary to protect our rights, protect your safety, or investigate fraud.
            </p>
          </SubSection>

          <SubSection title="4.3 Business Transfers">
            <p>
              If Barakah is involved in a merger, acquisition, or sale of assets, your information may be transferred
              as part of that transaction. We will notify you before your information is transferred and becomes subject
              to a different Privacy Policy.
            </p>
          </SubSection>
        </Section>

        <Section title="5. Data Retention">
          <p>
            We retain your account and financial data for as long as your account is active, or as needed to provide
            you with the Service. If you delete your account, we will delete or anonymise your personal data within
            30 days, except where we are required by law to retain it longer (e.g. fraud prevention, tax records).
          </p>
        </Section>

        <Section title="6. Data Security">
          <p>We protect your data using industry-standard measures:</p>
          <ul>
            <li>All data in transit is encrypted using TLS 1.2 or higher.</li>
            <li>Passwords are hashed with bcrypt (never stored in plaintext).</li>
            <li>Authentication tokens are stored in HttpOnly, Secure cookies (not accessible to JavaScript).</li>
            <li>Our database is not publicly accessible and is protected by network-level access controls.</li>
          </ul>
          <p>
            No method of electronic storage or transmission is 100% secure. While we use commercially reasonable
            safeguards, we cannot guarantee absolute security.
          </p>
        </Section>

        <Section title="7. Your Rights and Choices">
          <p>Depending on your location, you may have the following rights:</p>
          <ul>
            <li><strong>Access</strong> — request a copy of the personal data we hold about you.</li>
            <li><strong>Correction</strong> — request that we correct inaccurate data.</li>
            <li><strong>Deletion</strong> — request deletion of your account and associated data.</li>
            <li><strong>Portability</strong> — request your data in a machine-readable format (where technically feasible).</li>
            <li><strong>Objection / Restriction</strong> — object to or request restriction of certain processing activities.</li>
            <li><strong>Withdraw Consent</strong> — where processing is based on consent, you may withdraw at any time.</li>
          </ul>
          <p>
            To exercise any of these rights, please email us at{' '}
            <a href={`mailto:${CONTACT_EMAIL}`} className="text-emerald-600 hover:underline">{CONTACT_EMAIL}</a>.
            We will respond within 30 days.
          </p>
        </Section>

        <Section title="8. Children's Privacy">
          <p>
            The Service is not directed to children under the age of 13 (or 16 in the EEA). We do not knowingly
            collect personal information from children. If you believe a child has provided us with their personal
            information, please contact us and we will promptly delete it.
          </p>
        </Section>

        <Section title="9. International Data Transfers">
          <p>
            Our servers are currently hosted in the United States. If you are located outside the US, your data will
            be transferred to and processed in the US. By using the Service, you consent to this transfer. We rely
            on Standard Contractual Clauses (SCCs) where required for EEA/UK data transfers.
          </p>
        </Section>

        <Section title="10. Third-Party Links and Services">
          <p>
            The Service may display live market data (e.g. gold prices from CoinGecko) via public APIs. We are not
            responsible for the privacy practices of third-party services. We encourage you to review their privacy
            policies before interacting with them.
          </p>
        </Section>

        <Section title="11. Push Notifications">
          <p>
            If you grant permission, we may send push notifications for bill due reminders, hawl completion alerts,
            and other account-related events. You may disable push notifications at any time through your device
            settings. Disabling push notifications does not affect email reminders.
          </p>
        </Section>

        <Section title="12. Changes to This Policy">
          <p>
            We may update this Privacy Policy from time to time. If we make material changes, we will notify you
            by email or by a prominent notice in the app at least 7 days before the changes take effect. Continued
            use of the Service after the effective date constitutes acceptance of the updated policy.
          </p>
        </Section>

        <Section title="13. Contact Us">
          <p>If you have questions or concerns about this Privacy Policy or our data practices, please contact us:</p>
          <address className="not-italic mt-3 p-4 bg-gray-50 rounded-lg border border-gray-200">
            <strong>{COMPANY}</strong><br />
            Email:{' '}
            <a href={`mailto:${CONTACT_EMAIL}`} className="text-emerald-600 hover:underline">{CONTACT_EMAIL}</a><br />
            Website:{' '}
            <a href={SITE} className="text-emerald-600 hover:underline">{SITE}</a>
          </address>
        </Section>
      </main>

      {/* Footer */}
      <footer className="border-t border-gray-100 py-8 px-4 text-center text-xs text-gray-400">
        <p>© {new Date().getFullYear()} {COMPANY}. All rights reserved.</p>
        <div className="flex justify-center gap-4 mt-2">
          <a href="/terms" className="hover:text-gray-600">Terms of Service</a>
          <span>·</span>
          <a href="/privacy" className="hover:text-gray-600">Privacy Policy</a>
        </div>
      </footer>
    </div>
  );
}

function Section({ title, children }) {
  return (
    <section className="mb-8">
      <h2 className="text-base font-semibold text-gray-900 mb-3 pb-2 border-b border-gray-100">{title}</h2>
      <div className="space-y-3">{children}</div>
    </section>
  );
}

function SubSection({ title, children }) {
  return (
    <div className="mt-4">
      <h3 className="text-sm font-semibold text-gray-800 mb-2">{title}</h3>
      <div className="space-y-2 pl-0">
        {children}
      </div>
    </div>
  );
}
