export const metadata = {
  title: 'Terms of Service — Barakah',
  description: 'The terms and conditions governing your use of the Barakah personal finance application.',
};

const LAST_UPDATED = 'March 4, 2026';
const CONTACT_EMAIL = 'support@trybarakah.com';
const APP_NAME = 'Barakah';
const COMPANY = 'Barakah';
const SITE = 'https://trybarakah.com';

export default function TermsPage() {
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
          <h1 className="text-3xl font-bold">Terms of Service</h1>
          <p className="text-emerald-200 mt-2 text-sm">Last updated: {LAST_UPDATED}</p>
        </div>
      </header>

      {/* Body */}
      <main className="prose-legal max-w-3xl mx-auto px-4 py-12 text-gray-700 text-sm leading-relaxed">

        <section className="mb-8 p-5 bg-emerald-50 border border-emerald-100 rounded-xl">
          <p>
            Please read these Terms of Service (&ldquo;Terms&rdquo;) carefully before using the {APP_NAME} mobile
            application or website (collectively, the &ldquo;Service&rdquo;). By creating an account or using the
            Service, you agree to be bound by these Terms. If you do not agree, do not use the Service.
          </p>
        </section>

        <Section title="1. Acceptance of Terms">
          <p>
            These Terms constitute a legally binding agreement between you and {COMPANY} (&ldquo;we&rdquo;,
            &ldquo;us&rdquo;, or &ldquo;our&rdquo;). By accessing or using our Service, you confirm that you are at
            least 13 years old (or 16 years old if you are in the European Economic Area), have read and understood
            these Terms, and agree to be bound by them.
          </p>
          <p>
            We may update these Terms at any time. If we make material changes, we will notify you by email or
            through the app at least 7 days before they take effect. Your continued use of the Service after the
            effective date constitutes acceptance.
          </p>
        </Section>

        <Section title="2. Description of the Service">
          <p>
            Barakah is a Shariah-compliant personal finance application designed to help Muslims manage their
            finances in accordance with Islamic principles. The Service includes tools for:
          </p>
          <ul>
            <li>Tracking income, expenses, and budgets</li>
            <li>Managing bills and recurring payments</li>
            <li>Tracking debts, investments, and financial assets</li>
            <li>Calculating zakat obligations and monitoring hawl (lunar year) completion</li>
            <li>Recording sadaqah (charitable giving) and waqf (endowment) contributions</li>
            <li>Planning wasiyyah (Islamic will) asset allocation</li>
            <li>Screening investments for halal compliance and riba (interest) risk</li>
            <li>Managing shared household finances</li>
          </ul>
        </Section>

        <Section title="3. Accounts and Registration">
          <SubSection title="3.1 Account Creation">
            <p>
              To use the Service, you must create an account through the Barakah mobile application. You agree to
              provide accurate, current, and complete information during registration and to keep your account
              information up to date.
            </p>
          </SubSection>

          <SubSection title="3.2 Account Security">
            <p>
              You are responsible for maintaining the confidentiality of your password and for all activity that
              occurs under your account. You agree to notify us immediately at{' '}
              <a href={`mailto:${CONTACT_EMAIL}`} className="text-emerald-600 hover:underline">{CONTACT_EMAIL}</a>{' '}
              if you suspect unauthorised access to your account. We are not liable for losses arising from
              your failure to secure your account credentials.
            </p>
          </SubSection>

          <SubSection title="3.3 One Account Per Person">
            <p>
              Each person may maintain only one Barakah account. Creating multiple accounts or sharing your
              account credentials with others is prohibited.
            </p>
          </SubSection>
        </Section>

        <Section title="4. Not Financial, Legal, or Religious Advice">
          <p className="font-semibold text-gray-800">
            Barakah is a personal finance management tool, not a licensed financial adviser, legal adviser, or
            Islamic scholar. Nothing in the Service constitutes financial, investment, legal, tax, or religious advice.
          </p>
          <p>Specifically:</p>
          <ul>
            <li>
              <strong>Zakat calculations</strong> are provided as estimates based on the data you enter and generally
              accepted scholarly positions (e.g. AMJA Fatwa #96 for nisab). They are not fatwas. Consult a qualified
              Islamic scholar for your specific situation.
            </li>
            <li>
              <strong>Halal investment screening</strong> and <strong>riba detection</strong> are algorithmic tools
              based on publicly available data. They do not constitute a Shariah audit. Consult a qualified Shariah
              adviser before making investment decisions.
            </li>
            <li>
              <strong>Wasiyyah (will) guidance</strong> is for organisational purposes only and does not constitute
              legal advice. Consult a qualified solicitor or attorney to create a legally valid will.
            </li>
            <li>
              <strong>Credit score insights</strong> are educational estimates only and are not official credit scores.
            </li>
          </ul>
          <p>
            Market data (gold prices, exchange rates, etc.) is provided for informational purposes and may be delayed
            or inaccurate. We make no representation as to its accuracy or completeness.
          </p>
        </Section>

        <Section title="5. Acceptable Use">
          <p>You agree to use the Service only for lawful purposes and in accordance with these Terms. You agree not to:</p>
          <ul>
            <li>Violate any applicable local, national, or international law or regulation.</li>
            <li>Use the Service to commit fraud, money laundering, or any other financial crime.</li>
            <li>Attempt to gain unauthorised access to any part of the Service, its servers, or databases.</li>
            <li>Reverse-engineer, decompile, or disassemble any part of the Service.</li>
            <li>Upload or transmit viruses or any malicious code.</li>
            <li>Scrape, harvest, or collect data from the Service by automated means.</li>
            <li>Impersonate any person or entity or misrepresent your affiliation with any person or entity.</li>
            <li>Use the Service in any way that could damage, disable, overburden, or impair it.</li>
          </ul>
          <p>
            We reserve the right to suspend or terminate your account if we reasonably believe you have violated
            these restrictions.
          </p>
        </Section>

        <Section title="6. Intellectual Property">
          <SubSection title="6.1 Our Property">
            <p>
              The Service, including its design, code, features, text, graphics, logos, and all other content
              created by us, is owned by {COMPANY} and protected by applicable intellectual property laws. You may
              not reproduce, distribute, modify, or create derivative works without our prior written consent.
            </p>
          </SubSection>

          <SubSection title="6.2 Your Data">
            <p>
              You retain ownership of all financial and personal data you enter into the Service
              (&ldquo;Your Data&rdquo;). You grant us a limited, non-exclusive licence to store, process, and
              display Your Data solely to provide the Service to you.
            </p>
          </SubSection>

          <SubSection title="6.3 Feedback">
            <p>
              If you submit feedback, suggestions, or ideas about the Service, you grant us an unrestricted,
              perpetual, royalty-free licence to use such feedback for any purpose without obligation to you.
            </p>
          </SubSection>
        </Section>

        <Section title="7. Privacy">
          <p>
            Your use of the Service is also governed by our{' '}
            <a href="/privacy" className="text-emerald-600 hover:underline">Privacy Policy</a>, which is
            incorporated into these Terms by reference. Please review our Privacy Policy to understand our data
            practices.
          </p>
        </Section>

        <Section title="8. Third-Party Services">
          <p>
            The Service integrates with third-party services (e.g. market data APIs, email delivery providers).
            These integrations are provided for your convenience. We are not responsible for the availability,
            accuracy, or practices of third-party services. Your use of third-party services is governed by their
            respective terms and privacy policies.
          </p>
        </Section>

        <Section title="9. Availability and Modifications">
          <p>
            We strive to keep the Service available 24 hours a day, but we do not guarantee uninterrupted access.
            We may modify, suspend, or discontinue any feature of the Service at any time without notice. We will
            not be liable to you or any third party for any modification, suspension, or discontinuation.
          </p>
          <p>
            We reserve the right to add or remove features, change pricing (with advance notice), or discontinue
            the Service entirely. If we discontinue the Service, we will provide at least 30 days&apos; advance notice
            and the opportunity to export your data.
          </p>
        </Section>

        <Section title="10. Disclaimers">
          <p>
            THE SERVICE IS PROVIDED &ldquo;AS IS&rdquo; AND &ldquo;AS AVAILABLE&rdquo; WITHOUT WARRANTIES OF ANY KIND,
            EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
            PURPOSE, AND NON-INFRINGEMENT. WE DO NOT WARRANT THAT:
          </p>
          <ul>
            <li>The Service will be error-free, uninterrupted, or secure.</li>
            <li>Any calculations, estimates, or recommendations provided by the Service are accurate or complete.</li>
            <li>The Service meets your specific financial, religious, or legal needs.</li>
            <li>Market data or third-party data accessed through the Service is current or accurate.</li>
          </ul>
        </Section>

        <Section title="11. Limitation of Liability">
          <p>
            TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW, {COMPANY.toUpperCase()} SHALL NOT BE LIABLE FOR
            ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES, INCLUDING LOSS OF PROFITS,
            DATA, GOODWILL, OR OTHER INTANGIBLE LOSSES, ARISING OUT OF OR IN CONNECTION WITH:
          </p>
          <ul>
            <li>Your use of or inability to use the Service;</li>
            <li>Any financial decisions made in reliance on the Service;</li>
            <li>Errors or inaccuracies in zakat calculations, investment screening, or other features;</li>
            <li>Unauthorised access to your account or data;</li>
            <li>Any third-party conduct or content.</li>
          </ul>
          <p>
            IN NO EVENT SHALL OUR TOTAL LIABILITY TO YOU EXCEED THE GREATER OF (A) THE AMOUNT YOU PAID US IN THE
            12 MONTHS PRECEDING THE CLAIM, OR (B) USD $100.
          </p>
        </Section>

        <Section title="12. Indemnification">
          <p>
            You agree to indemnify, defend, and hold harmless {COMPANY}, its officers, directors, employees, and
            agents from any claims, liabilities, damages, costs, or expenses (including reasonable legal fees)
            arising out of your use of the Service, your violation of these Terms, or your violation of any
            third-party rights.
          </p>
        </Section>

        <Section title="13. Termination">
          <SubSection title="13.1 By You">
            <p>
              You may delete your account at any time through the app settings. Deletion is permanent and removes
              your personal and financial data from our systems within 30 days, subject to legal retention
              requirements.
            </p>
          </SubSection>

          <SubSection title="13.2 By Us">
            <p>
              We may suspend or terminate your account immediately, without notice, if you violate these Terms or
              if we reasonably believe your continued use poses a risk to other users or to the integrity of the
              Service. Upon termination, your right to use the Service ceases immediately.
            </p>
          </SubSection>
        </Section>

        <Section title="14. Governing Law and Disputes">
          <p>
            These Terms shall be governed by and construed in accordance with the laws of the State of Delaware,
            United States, without regard to its conflict of law provisions.
          </p>
          <p>
            Any dispute arising from these Terms or the Service shall first be attempted to be resolved through
            good-faith negotiation. If unresolved after 30 days, disputes shall be submitted to binding
            arbitration in accordance with the rules of the American Arbitration Association. You agree to
            waive your right to a jury trial or to participate in a class action lawsuit.
          </p>
          <p>
            Notwithstanding the above, either party may seek injunctive or other equitable relief in any court of
            competent jurisdiction to prevent irreparable harm.
          </p>
        </Section>

        <Section title="15. Severability and Waiver">
          <p>
            If any provision of these Terms is found to be unenforceable, the remaining provisions will continue
            in full force and effect. Our failure to enforce any provision of these Terms shall not constitute a
            waiver of that provision.
          </p>
        </Section>

        <Section title="16. Entire Agreement">
          <p>
            These Terms, together with our Privacy Policy, constitute the entire agreement between you and{' '}
            {COMPANY} regarding your use of the Service and supersede all prior agreements and understandings,
            whether written or oral, relating to the Service.
          </p>
        </Section>

        <Section title="17. Contact Us">
          <p>
            If you have questions about these Terms, please contact us:
          </p>
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
      <div className="space-y-2">{children}</div>
    </div>
  );
}
