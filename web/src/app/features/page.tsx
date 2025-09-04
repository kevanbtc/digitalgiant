import { Metadata } from 'next';
import { MainLayout } from '@/components/layout/main-layout';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import Link from 'next/link';
import {
  Users,
  Shield,
  DollarSign,
  MapPin,
  Smartphone,
  Globe,
  Zap,
  Lock,
  TrendingUp,
  Wallet,
  MessageSquare,
  BarChart3,
  CheckCircle,
  Star,
  CreditCard,
  QrCode,
  Bell,
  Award,
  Target,
} from 'lucide-react';

export const metadata: Metadata = {
  title: 'Features',
  description: 'Discover all the powerful features that make Digital Giant the ultimate platform for connection masters.',
};

const mainFeatures = [
  {
    icon: Users,
    title: 'Relationship Monetization',
    description: 'Transform your network into passive income',
    details: [
      'Blockchain-verified referral tracking',
      'Multi-level commission structure (12-50%)',
      'Transparent earning reports',
      'Automated commission payments',
    ],
  },
  {
    icon: Shield,
    title: 'Institutional Security',
    description: 'Enterprise-grade protection and compliance',
    details: [
      'Multi-signature treasury management',
      'KYC/AML compliance integration',
      'Professional custody support',
      'Real-time fraud monitoring',
    ],
  },
  {
    icon: MapPin,
    title: 'POC Check-ins',
    description: 'Get rewarded for physical networking',
    details: [
      'Location-based reward system',
      'QR code scanning at events',
      'Daily earning opportunities',
      'Gamified networking experience',
    ],
  },
  {
    icon: Wallet,
    title: 'Multi-Asset Wallet',
    description: 'Manage all your digital assets',
    details: [
      'Support for ETH, USDC, USDT, DAI',
      'Traditional payment integration',
      'Mobile wallet connectivity',
      'Secure cold storage options',
    ],
  },
];

const platformFeatures = [
  {
    icon: Smartphone,
    title: 'Accessibility First',
    description: 'QR code onboarding and SMS verification for all demographics',
  },
  {
    icon: Globe,
    title: 'Global Reach',
    description: 'Multi-currency support with traditional and crypto payments',
  },
  {
    icon: BarChart3,
    title: 'Advanced Analytics',
    description: 'Real-time insights into your network performance and earnings',
  },
  {
    icon: MessageSquare,
    title: 'AI Support',
    description: 'Intelligent assistance for optimizing your networking strategy',
  },
  {
    icon: Bell,
    title: 'Smart Notifications',
    description: 'Stay informed about opportunities and earnings',
  },
  {
    icon: Award,
    title: 'Achievement System',
    description: 'Unlock rewards and recognition for your networking milestones',
  },
];

const securityFeatures = [
  {
    icon: Lock,
    title: 'Multi-Signature Security',
    description: '3-of-5 enterprise security for treasury management',
  },
  {
    icon: Shield,
    title: 'KYC/AML Compliance',
    description: 'Chainalysis, Elliptic, and ComplyAdvantage integration',
  },
  {
    icon: Zap,
    title: 'AI Fraud Detection',
    description: 'Intelligent monitoring prevents rug pulls and fraud',
  },
  {
    icon: Target,
    title: 'Risk Assessment',
    description: 'Continuous monitoring and risk scoring',
  },
];

const integrations = [
  { name: 'Stripe', type: 'Payments', icon: CreditCard },
  { name: 'Twilio', type: 'SMS', icon: MessageSquare },
  { name: 'MetaMask', type: 'Wallet', icon: Wallet },
  { name: 'Jumio', type: 'KYC', icon: Shield },
  { name: 'Chainlink', type: 'Oracles', icon: Globe },
  { name: 'IPFS', type: 'Storage', icon: Lock },
];

export default function FeaturesPage() {
  return (
    <MainLayout>
      {/* Hero Section */}
      <section className="py-20 md:py-32 px-4 bg-gradient-to-b from-primary/5 to-background">
        <div className="container mx-auto text-center">
          <div className="max-w-4xl mx-auto space-y-8">
            <h1 className="text-4xl md:text-6xl font-bold tracking-tight">
              Powerful Features for{' '}
              <span className="text-primary">Connection Masters</span>
            </h1>
            <p className="text-xl md:text-2xl text-muted-foreground max-w-3xl mx-auto">
              Everything you need to transform your network into a thriving digital empire.
              Built with enterprise-grade security and accessibility in mind.
            </p>
            <div className="flex flex-col sm:flex-row gap-4 justify-center">
              <Button size="lg" asChild>
                <Link href="/auth/register">Start Building</Link>
              </Button>
              <Button size="lg" variant="outline" asChild>
                <Link href="/pricing">View Pricing</Link>
              </Button>
            </div>
          </div>
        </div>
      </section>

      {/* Main Features */}
      <section className="py-20 px-4">
        <div className="container mx-auto">
          <div className="text-center space-y-4 mb-16">
            <h2 className="text-3xl md:text-4xl font-bold">Core Features</h2>
            <p className="text-xl text-muted-foreground max-w-2xl mx-auto">
              The foundational tools that power your connection economy
            </p>
          </div>
          
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-12">
            {mainFeatures.map((feature, index) => {
              const Icon = feature.icon;
              return (
                <Card key={index} className="h-full">
                  <CardHeader>
                    <div className="flex items-center space-x-4">
                      <div className="w-14 h-14 bg-primary/10 rounded-xl flex items-center justify-center">
                        <Icon className="h-7 w-7 text-primary" />
                      </div>
                      <div>
                        <CardTitle className="text-2xl">{feature.title}</CardTitle>
                        <CardDescription className="text-base">
                          {feature.description}
                        </CardDescription>
                      </div>
                    </div>
                  </CardHeader>
                  <CardContent>
                    <ul className="space-y-3">
                      {feature.details.map((detail, idx) => (
                        <li key={idx} className="flex items-center space-x-3">
                          <CheckCircle className="h-5 w-5 text-green-500 flex-shrink-0" />
                          <span className="text-muted-foreground">{detail}</span>
                        </li>
                      ))}
                    </ul>
                  </CardContent>
                </Card>
              );
            })}
          </div>
        </div>
      </section>

      {/* Platform Features */}
      <section className="py-20 px-4 bg-muted/30">
        <div className="container mx-auto">
          <div className="text-center space-y-4 mb-16">
            <h2 className="text-3xl md:text-4xl font-bold">Platform Capabilities</h2>
            <p className="text-xl text-muted-foreground">
              Advanced tools to maximize your networking potential
            </p>
          </div>
          
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
            {platformFeatures.map((feature, index) => {
              const Icon = feature.icon;
              return (
                <Card key={index} className="h-full">
                  <CardHeader>
                    <div className="w-12 h-12 bg-primary/10 rounded-lg flex items-center justify-center mb-4">
                      <Icon className="h-6 w-6 text-primary" />
                    </div>
                    <CardTitle className="text-xl">{feature.title}</CardTitle>
                  </CardHeader>
                  <CardContent>
                    <CardDescription className="text-base">
                      {feature.description}
                    </CardDescription>
                  </CardContent>
                </Card>
              );
            })}
          </div>
        </div>
      </section>

      {/* Security Features */}
      <section className="py-20 px-4">
        <div className="container mx-auto">
          <div className="text-center space-y-4 mb-16">
            <h2 className="text-3xl md:text-4xl font-bold">
              Enterprise-Grade Security
            </h2>
            <p className="text-xl text-muted-foreground max-w-2xl mx-auto">
              Your assets and data are protected by institutional-level security measures
            </p>
          </div>
          
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-8">
            {securityFeatures.map((feature, index) => {
              const Icon = feature.icon;
              return (
                <Card key={index} className="text-center h-full">
                  <CardHeader>
                    <div className="w-16 h-16 bg-red-50 rounded-xl flex items-center justify-center mx-auto mb-4">
                      <Icon className="h-8 w-8 text-red-600" />
                    </div>
                    <CardTitle className="text-lg">{feature.title}</CardTitle>
                  </CardHeader>
                  <CardContent>
                    <CardDescription className="text-sm">
                      {feature.description}
                    </CardDescription>
                  </CardContent>
                </Card>
              );
            })}
          </div>
        </div>
      </section>

      {/* Integrations */}
      <section className="py-20 px-4 bg-muted/30">
        <div className="container mx-auto">
          <div className="text-center space-y-4 mb-16">
            <h2 className="text-3xl md:text-4xl font-bold">Trusted Integrations</h2>
            <p className="text-xl text-muted-foreground">
              Seamlessly connected with industry-leading services
            </p>
          </div>
          
          <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-8">
            {integrations.map((integration, index) => {
              const Icon = integration.icon;
              return (
                <Card key={index} className="text-center h-full">
                  <CardHeader className="pb-2">
                    <div className="w-12 h-12 bg-primary/10 rounded-lg flex items-center justify-center mx-auto">
                      <Icon className="h-6 w-6 text-primary" />
                    </div>
                  </CardHeader>
                  <CardContent className="pt-0">
                    <div className="font-semibold text-sm">{integration.name}</div>
                    <div className="text-xs text-muted-foreground">{integration.type}</div>
                  </CardContent>
                </Card>
              );
            })}
          </div>
        </div>
      </section>

      {/* Accessibility Features */}
      <section className="py-20 px-4">
        <div className="container mx-auto">
          <div className="max-w-4xl mx-auto">
            <div className="text-center space-y-4 mb-16">
              <h2 className="text-3xl md:text-4xl font-bold">
                Accessibility First Design
              </h2>
              <p className="text-xl text-muted-foreground">
                Built for everyone, regardless of technical skill or physical ability
              </p>
            </div>
            
            <div className="grid grid-cols-1 md:grid-cols-2 gap-12 items-center">
              <div className="space-y-6">
                <div className="space-y-4">
                  <div className="flex items-start space-x-4">
                    <QrCode className="h-6 w-6 text-primary mt-1" />
                    <div>
                      <h3 className="font-semibold">QR Code Onboarding</h3>
                      <p className="text-muted-foreground">Simple scan-to-join process for all demographics</p>
                    </div>
                  </div>
                  <div className="flex items-start space-x-4">
                    <MessageSquare className="h-6 w-6 text-primary mt-1" />
                    <div>
                      <h3 className="font-semibold">SMS Verification</h3>
                      <p className="text-muted-foreground">Works without smartphones or internet</p>
                    </div>
                  </div>
                  <div className="flex items-start space-x-4">
                    <Users className="h-6 w-6 text-primary mt-1" />
                    <div>
                      <h3 className="font-semibold">Screen Reader Support</h3>
                      <p className="text-muted-foreground">Full ARIA compliance and keyboard navigation</p>
                    </div>
                  </div>
                  <div className="flex items-start space-x-4">
                    <Target className="h-6 w-6 text-primary mt-1" />
                    <div>
                      <h3 className="font-semibold">High Contrast Modes</h3>
                      <p className="text-muted-foreground">Vision accessibility features built-in</p>
                    </div>
                  </div>
                </div>
              </div>
              <div className="bg-primary/5 p-8 rounded-2xl">
                <div className="space-y-4">
                  <h3 className="text-2xl font-bold">WCAG 2.1 AA Compliant</h3>
                  <p className="text-muted-foreground">
                    Our platform meets and exceeds international accessibility standards, 
                    ensuring everyone can participate in the connection economy.
                  </p>
                  <Button variant="outline" asChild>
                    <Link href="/accessibility">Learn More About Accessibility</Link>
                  </Button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* CTA Section */}
      <section className="py-20 px-4 bg-primary text-primary-foreground">
        <div className="container mx-auto text-center">
          <div className="max-w-3xl mx-auto space-y-8">
            <h2 className="text-3xl md:text-4xl font-bold">
              Ready to Experience These Features?
            </h2>
            <p className="text-xl opacity-90">
              Join thousands of connection masters already building their digital empires.
            </p>
            <div className="flex flex-col sm:flex-row gap-4 justify-center">
              <Button size="lg" variant="secondary" asChild>
                <Link href="/auth/register">Get Started Free</Link>
              </Button>
              <Button size="lg" variant="outline" className="border-primary-foreground text-primary-foreground hover:bg-primary-foreground hover:text-primary" asChild>
                <Link href="/contact">Schedule Demo</Link>
              </Button>
            </div>
          </div>
        </div>
      </section>
    </MainLayout>
  );
}