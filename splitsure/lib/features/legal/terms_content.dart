/// SplitSure Terms & Conditions (EN / FR).
///
/// Written for how the app works today (Basic / Pro, paid final agreements,
/// MeSomb mobile money, Music Passport, Opportunity Hub, Reach). Have a lawyer
/// review it before relying on it, and update [termsLastUpdated] on every change.
library;

final termsLastUpdated = DateTime(2026, 11, 24);

class TermsSection {
  final String title;
  final List<String> paragraphs;
  const TermsSection(this.title, this.paragraphs);
}

List<TermsSection> termsFor(String languageCode) => languageCode == 'fr' ? _fr : _en;

const _en = <TermsSection>[
  TermsSection('About SplitSure', [
    'SplitSure is a platform for musicians and music professionals. It helps you document collaborations and revenue splits ("Protect"), present your professional profile ("Music Passport"), find and offer collaborations ("Opportunity Hub" and "DealFlow"), and prepare promotional content ("Reach").',
    'By creating an account or using SplitSure you agree to these Terms. If you do not agree, please do not use the app.',
  ]),
  TermsSection('Your account', [
    'You must provide accurate information and keep it up to date. You are responsible for everything done with your account and for keeping your password secret.',
    'You must be at least 18 years old, or have the permission of a parent or legal guardian, to use SplitSure.',
    'If you believe your account has been accessed without your permission, change your password immediately (Login > Forgot password) and contact us.',
  ]),
  TermsSection('Plans and payments', [
    'Basic plan (free): create projects and agreements, invite collaborators, publish a Music Passport, post one collaboration opportunity and apply to others. Generating the final agreement document costs 50 FCFA per agreement.',
    'Pro plan (100 FCFA, one-time unlock unless stated otherwise in the app): unlimited projects, unlimited final agreement documents, unlimited opportunity posts and access to Reach.',
    'Payments are made with MTN Mobile Money or Orange Money through our payment provider, MeSomb. A plan or document is only unlocked after the payment has been confirmed by the provider. If a payment fails or is cancelled, nothing is charged and your account stays as it was.',
    'Payments for services that have already been delivered (an activated Pro plan or a generated final agreement) are not refundable, except where the law requires it or where you were charged more than once for the same item. A receipt is available for every successful payment in Subscription > Payment history.',
    'Prices are shown in the app before you pay and may change in the future. A change never affects a payment you have already made.',
  ]),
  TermsSection('Collaboration agreements', [
    'Agreements created in SplitSure record what the parties have agreed: roles, contributions and percentage shares. Each party reviews the agreement and accepts it, requests changes or declines it. Every new version is kept with the date and the responses of each party.',
    'SplitSure is not a party to your agreements and does not collect, hold or distribute royalties or other income on your behalf.',
    'The documents produced by SplitSure are provided for record-keeping and do not constitute legal advice. Their legal effect depends on the laws that apply to you. We recommend that you seek independent legal advice before relying on an agreement as a binding contract.',
  ]),
  TermsSection('Your content', [
    'You keep ownership of everything you upload or create in SplitSure: music, cover art, videos, profile information, captions and documents ("your content").',
    'You give SplitSure a limited, non-exclusive licence to store, process and display your content only as needed to run the features you use, for example to show your public Music Passport or to generate a promotional video.',
    'You confirm that you have the rights to the content you upload, including music and artwork, and that it does not infringe anyone else\'s rights.',
  ]),
  TermsSection('Music Passport and public information', [
    'Your Music Passport is visible to others only after you publish it, and only the sections you mark as public are shown. You can edit, hide or unpublish it at any time.',
    'Information you choose to make public may be seen, shared or saved by other people. Please only publish what you are comfortable sharing.',
  ]),
  TermsSection('Opportunity Hub and DealFlow', [
    'Opportunities must describe real collaborations. Spam, misleading offers, requests for upfront payments from applicants, and discriminatory, offensive or illegal content are not allowed.',
    'Decisions to shortlist, accept or reject applicants are made by the person who posted the opportunity. SplitSure does not guarantee that an opportunity will lead to a collaboration or to payment.',
    'Deal terms discussed in a DealFlow workspace only become an agreement once they are moved to Protect and accepted by every party.',
  ]),
  TermsSection('Reach and social media', [
    'Reach prepares captions, hashtags and promotional videos from the information you provide. You decide what to publish and where.',
    'SplitSure never asks for or stores your social media passwords. Content is shared through your device\'s share menu or downloaded for you to post yourself. You are responsible for following the rules of each platform (for example TikTok, Facebook, WhatsApp and YouTube) and for having the rights to the music and images you post.',
  ]),
  TermsSection('Acceptable use', [
    'Do not use SplitSure to break the law, to harass or impersonate anyone, to upload malicious software, to access other people\'s accounts or data, or to interfere with the service.',
    'We may remove content or suspend accounts that break these Terms, and we will tell you why where we reasonably can.',
  ]),
  TermsSection('Privacy and data', [
    'We collect the information you give us (such as your name, email address, phone number, profile and the content you create) and basic technical information needed to run the app securely.',
    'We use your information to provide SplitSure\'s features, to process payments, to send the notifications and emails you need (for example agreement invitations, payment confirmations and password resets) and to keep the service secure. We do not sell your personal information.',
    'Your data is stored with our hosting provider (Supabase). Payment details are handled by MeSomb and the mobile money operators; SplitSure never sees your mobile money PIN.',
    'You can update your profile at any time and can ask us to delete your account. Some records, such as agreements other parties have accepted and payment records, may be kept where we are required to or where other parties rely on them.',
  ]),
  TermsSection('Notifications', [
    'SplitSure sends in-app notifications and, if you allow them, push notifications and emails about activity that concerns you. You can choose which notifications you receive in Settings > Notification preferences.',
  ]),
  TermsSection('Availability and liability', [
    'We work hard to keep SplitSure available and secure, but the service is provided "as is" and may sometimes be interrupted for maintenance or reasons outside our control.',
    'To the extent permitted by law, SplitSure is not liable for indirect losses, for disputes between users, or for losses that result from agreements, collaborations or publications made using the app. Nothing in these Terms limits rights you have under consumer law.',
  ]),
  TermsSection('Ending your use of SplitSure', [
    'You can stop using SplitSure at any time and request the deletion of your account. We may suspend or close accounts that seriously or repeatedly break these Terms.',
  ]),
  TermsSection('Changes to these Terms', [
    'We may update these Terms as SplitSure evolves. When we make important changes we will let you know in the app. The date of the latest update is shown at the top of this page. If you keep using SplitSure after a change, the updated Terms apply.',
  ]),
  TermsSection('Applicable law and contact', [
    'These Terms are governed by the laws of the Republic of Cameroon. We will always try to resolve disagreements amicably first.',
    'Questions about these Terms or your data? Contact us through the contact options in the SplitSure app or at splitsure.vercel.app.',
  ]),
];

const _fr = <TermsSection>[
  TermsSection('À propos de SplitSure', [
    'SplitSure est une plateforme destinée aux musiciens et aux professionnels de la musique. Elle vous aide à documenter vos collaborations et le partage des revenus (« Protect »), à présenter votre profil professionnel (« Music Passport »), à trouver et proposer des collaborations (« Opportunity Hub » et « DealFlow ») et à préparer du contenu promotionnel (« Reach »).',
    'En créant un compte ou en utilisant SplitSure, vous acceptez les présentes Conditions. Si vous ne les acceptez pas, veuillez ne pas utiliser l\'application.',
  ]),
  TermsSection('Votre compte', [
    'Vous devez fournir des informations exactes et les tenir à jour. Vous êtes responsable de toute activité effectuée avec votre compte et de la confidentialité de votre mot de passe.',
    'Vous devez avoir au moins 18 ans, ou l\'autorisation d\'un parent ou tuteur légal, pour utiliser SplitSure.',
    'Si vous pensez que quelqu\'un a accédé à votre compte sans autorisation, changez immédiatement votre mot de passe (Connexion > Mot de passe oublié) et contactez-nous.',
  ]),
  TermsSection('Formules et paiements', [
    'Formule Basique (gratuite) : créer des projets et des accords, inviter des collaborateurs, publier un Music Passport, publier une annonce de collaboration et postuler aux autres. La génération du document final d\'un accord coûte 50 FCFA par accord.',
    'Formule Pro (100 FCFA, déblocage unique sauf indication contraire dans l\'application) : projets illimités, documents finaux illimités, annonces illimitées et accès à Reach.',
    'Les paiements se font par MTN Mobile Money ou Orange Money via notre prestataire de paiement, MeSomb. Une formule ou un document n\'est débloqué qu\'après confirmation du paiement par le prestataire. Si un paiement échoue ou est annulé, rien n\'est prélevé et votre compte reste inchangé.',
    'Les paiements pour des services déjà fournis (formule Pro activée ou accord final généré) ne sont pas remboursables, sauf si la loi l\'exige ou si vous avez été débité plusieurs fois pour le même élément. Un reçu est disponible pour chaque paiement réussi dans Abonnement > Historique des paiements.',
    'Les prix sont indiqués dans l\'application avant le paiement et peuvent évoluer. Une modification n\'affecte jamais un paiement déjà effectué.',
  ]),
  TermsSection('Accords de collaboration', [
    'Les accords créés dans SplitSure consignent ce que les parties ont convenu : rôles, contributions et parts en pourcentage. Chaque partie examine l\'accord puis l\'accepte, demande des modifications ou le refuse. Chaque nouvelle version est conservée avec la date et les réponses de chaque partie.',
    'SplitSure n\'est pas partie à vos accords et ne perçoit, ne détient ni ne distribue de redevances ou d\'autres revenus pour votre compte.',
    'Les documents produits par SplitSure sont fournis à des fins d\'archivage et ne constituent pas un conseil juridique. Leur portée juridique dépend des lois qui vous sont applicables. Nous vous recommandons de consulter un conseiller juridique indépendant avant de considérer un accord comme un contrat contraignant.',
  ]),
  TermsSection('Votre contenu', [
    'Vous restez propriétaire de tout ce que vous téléversez ou créez dans SplitSure : musique, pochettes, vidéos, informations de profil, légendes et documents (« votre contenu »).',
    'Vous accordez à SplitSure une licence limitée et non exclusive pour stocker, traiter et afficher votre contenu uniquement dans la mesure nécessaire au fonctionnement des fonctionnalités que vous utilisez, par exemple pour afficher votre Music Passport public ou générer une vidéo promotionnelle.',
    'Vous confirmez disposer des droits sur le contenu que vous téléversez, y compris la musique et les visuels, et qu\'il ne porte pas atteinte aux droits d\'autrui.',
  ]),
  TermsSection('Music Passport et informations publiques', [
    'Votre Music Passport n\'est visible par les autres qu\'après sa publication, et seules les sections que vous marquez comme publiques sont affichées. Vous pouvez le modifier, le masquer ou le dépublier à tout moment.',
    'Les informations que vous rendez publiques peuvent être vues, partagées ou enregistrées par d\'autres personnes. Ne publiez que ce que vous êtes prêt à partager.',
  ]),
  TermsSection('Opportunity Hub et DealFlow', [
    'Les annonces doivent décrire de véritables collaborations. Le spam, les offres trompeuses, les demandes de paiement préalable aux candidats et les contenus discriminatoires, offensants ou illégaux sont interdits.',
    'Les décisions de présélectionner, d\'accepter ou de refuser des candidats appartiennent à l\'auteur de l\'annonce. SplitSure ne garantit pas qu\'une annonce aboutira à une collaboration ou à une rémunération.',
    'Les conditions discutées dans un espace DealFlow ne deviennent un accord qu\'une fois transférées dans Protect et acceptées par toutes les parties.',
  ]),
  TermsSection('Reach et réseaux sociaux', [
    'Reach prépare des légendes, des hashtags et des vidéos promotionnelles à partir des informations que vous fournissez. Vous décidez de ce que vous publiez et où.',
    'SplitSure ne demande ni ne conserve jamais vos mots de passe de réseaux sociaux. Le contenu est partagé via le menu de partage de votre appareil ou téléchargé pour que vous le publiiez vous-même. Vous êtes responsable du respect des règles de chaque plateforme (par exemple TikTok, Facebook, WhatsApp et YouTube) et de la détention des droits sur la musique et les images publiées.',
  ]),
  TermsSection('Utilisation acceptable', [
    'N\'utilisez pas SplitSure pour enfreindre la loi, harceler ou usurper l\'identité de quiconque, diffuser des logiciels malveillants, accéder aux comptes ou données d\'autrui, ou perturber le service.',
    'Nous pouvons retirer du contenu ou suspendre des comptes qui enfreignent les présentes Conditions et nous vous en indiquerons la raison lorsque cela est raisonnablement possible.',
  ]),
  TermsSection('Confidentialité et données', [
    'Nous collectons les informations que vous nous fournissez (nom, adresse e-mail, numéro de téléphone, profil et contenus créés) ainsi que les informations techniques de base nécessaires au fonctionnement sécurisé de l\'application.',
    'Nous utilisons vos informations pour fournir les fonctionnalités de SplitSure, traiter les paiements, envoyer les notifications et e-mails nécessaires (invitations à des accords, confirmations de paiement, réinitialisations de mot de passe…) et sécuriser le service. Nous ne vendons pas vos données personnelles.',
    'Vos données sont hébergées chez notre prestataire (Supabase). Les informations de paiement sont traitées par MeSomb et les opérateurs de mobile money ; SplitSure ne voit jamais votre code secret mobile money.',
    'Vous pouvez mettre à jour votre profil à tout moment et demander la suppression de votre compte. Certains éléments, comme les accords acceptés par d\'autres parties et les enregistrements de paiement, peuvent être conservés lorsque nous y sommes tenus ou que d\'autres parties en dépendent.',
  ]),
  TermsSection('Notifications', [
    'SplitSure envoie des notifications dans l\'application et, si vous les autorisez, des notifications push et des e-mails concernant l\'activité qui vous concerne. Vous pouvez choisir les notifications reçues dans Paramètres > Préférences de notification.',
  ]),
  TermsSection('Disponibilité et responsabilité', [
    'Nous faisons tout notre possible pour que SplitSure reste disponible et sécurisé, mais le service est fourni « en l\'état » et peut parfois être interrompu pour maintenance ou pour des raisons indépendantes de notre volonté.',
    'Dans les limites permises par la loi, SplitSure n\'est pas responsable des pertes indirectes, des litiges entre utilisateurs ni des pertes résultant d\'accords, de collaborations ou de publications réalisés via l\'application. Rien dans les présentes Conditions ne limite les droits dont vous disposez en tant que consommateur.',
  ]),
  TermsSection('Fin d\'utilisation de SplitSure', [
    'Vous pouvez cesser d\'utiliser SplitSure à tout moment et demander la suppression de votre compte. Nous pouvons suspendre ou fermer les comptes qui enfreignent gravement ou de manière répétée les présentes Conditions.',
  ]),
  TermsSection('Modifications des Conditions', [
    'Nous pouvons mettre à jour ces Conditions à mesure que SplitSure évolue. En cas de modification importante, nous vous en informerons dans l\'application. La date de la dernière mise à jour figure en haut de cette page. Si vous continuez à utiliser SplitSure après une modification, les Conditions mises à jour s\'appliquent.',
  ]),
  TermsSection('Droit applicable et contact', [
    'Les présentes Conditions sont régies par les lois de la République du Cameroun. Nous chercherons toujours d\'abord à régler les différends à l\'amiable.',
    'Une question sur ces Conditions ou sur vos données ? Contactez-nous via les options de contact de l\'application SplitSure ou sur splitsure.vercel.app.',
  ]),
];
