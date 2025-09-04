import { Metadata } from 'next';
import { MainLayout } from '@/components/layout/main-layout';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { formatCurrency } from '@/lib/utils';
import { PACK_TYPES, COMMISSION_RATES } from '@/lib/constants';
import Link from 'next/link';
import {
  CheckCircle,
  Star,
  Zap,
  Crown,
  ArrowRight,
  DollarSign,
  TrendingUp,
  Users,
  Award,
  Calculator,
  Percent,
} from 'lucide-react';

export const metadata: Metadata = {
  title: 'Pricing',
  description: 'Choose the perfect pack for your networking ambitions. Transparent pricing with no hidden fees.',
};

const packDetails = {
  STARTER: {
    ...PACK_TYPES.STARTER,
    icon: Zap,
    color: 'blue',
    popular: false,
    earningsExample: {
      monthlyReferrals: 5,
      monthlyEarnings: 37.50,
      yearlyEarnings: 450,
    },
  },
  PROFESSIONAL: {
    ...PACK_TYPES.PROFESSIONAL,
    icon: Star,
    color: 'primary',
    popular: true,
    earningsExample: {
      monthlyReferrals: 10,
      monthlyEarnings: 200,
      yearlyEarnings: 2400,
    },
  },
  EXECUTIVE: {
    ...PACK_TYPES.EXECUTIVE,
    icon: Crown,
    color: 'purple',
    popular: false,
    earningsExample: {
      monthlyReferrals: 15,
      monthlyEarnings: 750,
      yearlyEarnings: 9000,
    },
  },
};

const feeStructure = [
  {
    type: 'Pack Sales',
    rate: '2.5%',
    description: 'Transaction fee on all pack purchases',
  },
  {
    type: 'Token Transfers',
    rate: '1.5%',
    description: 'Fee for blockchain token transfers',
  },
  {
    type: 'Merchant Transactions',
    rate: '3.0%',
    description: 'Fee for merchant payment processing',
  },
  {
    type: 'Withdrawal Fees',
    rate: 'Variable',
    description: 'Network fees for crypto withdrawals',
  },
];

const commissionStructure = [
  {
    level: 'Direct Referral',
    rate: COMMISSION_RATES.DIRECT_REFERRAL,
    description: 'People you directly refer',
  },
  {
    level: 'Level 2',
    rate: COMMISSION_RATES.LEVEL_2,
    description: 'People referred by your direct referrals',
  },
  {
    level: 'Level 3',
    rate: COMMISSION_RATES.LEVEL_3,
    description: 'Third level in your network',
  },
  {
    level: 'Level 4',
    rate: COMMISSION_RATES.LEVEL_4,
    description: 'Fourth level in your network',
  },
  {
    level: 'Level 5',
    rate: COMMISSION_RATES.LEVEL_5,
    description: 'Fifth level in your network',
  },
];

const faqs = [
  {
    question: 'Are there any hidden fees?',
    answer: 'No hidden fees. All costs are transparent and disclosed upfront. You only pay transaction fees when you earn.',
  },
  {
    question: 'Can I upgrade my pack later?',
    answer: 'Yes, you can upgrade to a higher pack at any time. You\'ll only pay the difference in price.',
  },
  {
    question: 'How are commissions calculated?',
    answer: 'Commissions are calculated based on the pack margin and commission structure. All calculations are transparent and tracked on the blockchain.',
  },
  {
    question: 'When do I receive my earnings?',
    answer: 'Earnings are processed and distributed automatically every 24 hours after the escrow period.',
  },
  {
    question: 'Is there a refund policy?',
    answer: 'Yes, we offer a 30-day money-back guarantee for all pack purchases if you\'re not satisfied.',
  },
];

export default function PricingPage() {
  return (
    <MainLayout>
      {/* Hero Section */}
      <section className="py-20 md:py-32 px-4 bg-gradient-to-b from-primary/5 to-background">
        <div className="container mx-auto text-center">
          <div className="max-w-4xl mx-auto space-y-8">
            <h1 className="text-4xl md:text-6xl font-bold tracking-tight">
              Choose Your{' '}
              <span className="text-primary">Empire Builder</span>
            </h1>
            <p className="text-xl md:text-2xl text-muted-foreground max-w-3xl mx-auto">
              Transparent pricing with no hidden fees. Start free and scale as you grow.
              The more you refer, the more you earn.
            </p>
            <div className="flex items-center justify-center space-x-4 text-sm text-muted-foreground">
              <div className="flex items-center space-x-1">
                <CheckCircle className="h-4 w-4 text-green-500" />
                <span>30-day money back guarantee</span>
              </div>
              <div className="flex items-center space-x-1">
                <CheckCircle className="h-4 w-4 text-green-500" />
                <span>No monthly fees</span>
              </div>
              <div className="flex items-center space-x-1">
                <CheckCircle className="h-4 w-4 text-green-500" />
                <span>Instant earnings</span>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Pricing Cards */}
      <section className="py-20 px-4">
        <div className="container mx-auto">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8 max-w-6xl mx-auto">
            {Object.entries(packDetails).map(([key, pack]) => {
              const Icon = pack.icon;
              return (
                <Card key={key} className={`relative h-full ${pack.popular ? 'ring-2 ring-primary shadow-lg scale-105' : ''}`}>
                  {pack.popular && (
                    <div className="absolute -top-4 left-1/2 transform -translate-x-1/2">
                      <span className="bg-primary text-primary-foreground px-4 py-1 rounded-full text-sm font-medium flex items-center space-x-1">
                        <Star className="h-4 w-4" />
                        <span>Most Popular</span>
                      </span>
                    </div>
                  )}
                  
                  <CardHeader className="text-center pb-4">
                    <div className={`w-16 h-16 bg-${pack.color}-100 rounded-2xl flex items-center justify-center mx-auto mb-4`}>
                      <Icon className={`h-8 w-8 text-${pack.color}-600`} />
                    </div>
                    <CardTitle className="text-2xl">{pack.name}</CardTitle>
                    <div className="space-y-2">
                      <div className="text-4xl font-bold text-primary">
                        {formatCurrency(pack.price)}
                      </div>
                      <CardDescription className="text-lg">
                        {Math.round(pack.margin * 100)}% commission rate
                      </CardDescription>
                    </div>
                  </CardHeader>
                  
                  <CardContent className="space-y-6">
                    {/* Features */}
                    <div className="space-y-3">
                      {pack.features.map((feature, index) => (
                        <div key={index} className="flex items-center space-x-3">
                          <CheckCircle className="h-5 w-5 text-green-500 flex-shrink-0" />
                          <span className="text-sm">{feature}</span>
                        </div>
                      ))}
                    </div>
                    
                    {/* Earnings Example */}
                    <div className="bg-muted/50 p-4 rounded-lg">
                      <h4 className="font-semibold mb-2 text-sm">Earnings Example</h4>
                      <div className="space-y-1 text-sm text-muted-foreground">
                        <div className="flex justify-between">
                          <span>{pack.earningsExample.monthlyReferrals} referrals/month:</span>
                          <span className="font-medium text-foreground">
                            {formatCurrency(pack.earningsExample.monthlyEarnings)}
                          </span>
                        </div>
                        <div className="flex justify-between">
                          <span>Yearly potential:</span>
                          <span className="font-medium text-primary">
                            {formatCurrency(pack.earningsExample.yearlyEarnings)}
                          </span>
                        </div>
                      </div>
                    </div>
                    
                    <Button 
                      className="w-full" 
                      variant={pack.popular ? 'default' : 'outline'}
                      size="lg"
                      asChild
                    >
                      <Link href="/auth/register">
                        Get Started
                        <ArrowRight className="ml-2 h-4 w-4" />
                      </Link>
                    </Button>
                  </CardContent>
                </Card>
              );
            })}
          </div>
        </div>
      </section>

      {/* Commission Structure */}
      <section className="py-20 px-4 bg-muted/30">
        <div className="container mx-auto">
          <div className="text-center space-y-4 mb-16">
            <h2 className="text-3xl md:text-4xl font-bold">Commission Structure</h2>
            <p className="text-xl text-muted-foreground">
              Transparent multi-level earnings with blockchain verification
            </p>
          </div>
          
          <div className="max-w-4xl mx-auto">
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center space-x-2">
                  <Percent className="h-5 w-5 text-primary" />
                  <span>Multi-Level Commission Rates</span>
                </CardTitle>
                <CardDescription>
                  Earn from every level of your network with decreasing rates
                </CardDescription>
              </CardHeader>
              <CardContent>
                <div className="space-y-4">
                  {commissionStructure.map((level, index) => (
                    <div key={index} className="flex items-center justify-between p-4 bg-muted/50 rounded-lg">
                      <div>
                        <div className="font-semibold">{level.level}</div>
                        <div className="text-sm text-muted-foreground">{level.description}</div>
                      </div>
                      <div className="text-2xl font-bold text-primary">
                        {(level.rate * 100).toFixed(0)}%
                      </div>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>
          </div>
        </div>
      </section>

      {/* Fee Structure */}
      <section className="py-20 px-4">
        <div className="container mx-auto">
          <div className="text-center space-y-4 mb-16">
            <h2 className="text-3xl md:text-4xl font-bold">Fee Structure</h2>
            <p className="text-xl text-muted-foreground">
              Simple, transparent fees with no surprises
            </p>
          </div>
          
          <div className="max-w-4xl mx-auto">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
              {feeStructure.map((fee, index) => (
                <Card key={index}>
                  <CardHeader>
                    <CardTitle className="flex items-center justify-between">
                      <span>{fee.type}</span>
                      <span className="text-primary">{fee.rate}</span>
                    </CardTitle>
                  </CardHeader>
                  <CardContent>
                    <CardDescription>{fee.description}</CardDescription>
                  </CardContent>
                </Card>
              ))}
            </div>
          </div>
        </div>
      </section>

      {/* Earnings Calculator */}
      <section className="py-20 px-4 bg-muted/30">
        <div className="container mx-auto">
          <div className="text-center space-y-4 mb-16">
            <h2 className="text-3xl md:text-4xl font-bold">Earnings Calculator</h2>
            <p className="text-xl text-muted-foreground">
              See your potential earnings based on network size
            </p>
          </div>
          
          <div className="max-w-2xl mx-auto">
            <Card>
              <CardHeader className="text-center">
                <CardTitle className="flex items-center justify-center space-x-2">
                  <Calculator className="h-5 w-5 text-primary" />
                  <span>Potential Monthly Earnings</span>
                </CardTitle>
                <CardDescription>
                  Based on Professional Pack with 10 direct referrals
                </CardDescription>
              </CardHeader>
              <CardContent>
                <div className="space-y-6">
                  <div className="text-center">
                    <div className="text-4xl font-bold text-primary mb-2">
                      {formatCurrency(1850)}
                    </div>
                    <div className="text-muted-foreground">
                      Estimated monthly earnings with a 50-person network
                    </div>
                  </div>
                  
                  <div className="space-y-3">
                    <div className="flex justify-between items-center p-3 bg-muted/50 rounded-lg">
                      <span>10 Direct Referrals (12%)</span>
                      <span className="font-semibold">{formatCurrency(600)}</span>
                    </div>
                    <div className="flex justify-between items-center p-3 bg-muted/50 rounded-lg">
                      <span>20 Level 2 (8%)</span>
                      <span className="font-semibold">{formatCurrency(800)}</span>
                    </div>
                    <div className="flex justify-between items-center p-3 bg-muted/50 rounded-lg">
                      <span>20 Level 3 (5%)</span>
                      <span className="font-semibold">{formatCurrency(450)}</span>
                    </div>
                  </div>
                  
                  <Button className="w-full" asChild>
                    <Link href="/auth/register">
                      Start Building Your Network
                    </Link>
                  </Button>
                </div>
              </CardContent>
            </Card>
          </div>
        </div>
      </section>

      {/* FAQ */}
      <section className="py-20 px-4">
        <div className="container mx-auto">
          <div className="text-center space-y-4 mb-16">
            <h2 className="text-3xl md:text-4xl font-bold">Frequently Asked Questions</h2>
            <p className="text-xl text-muted-foreground">
              Everything you need to know about our pricing
            </p>
          </div>
          
          <div className="max-w-3xl mx-auto space-y-6">
            {faqs.map((faq, index) => (
              <Card key={index}>
                <CardHeader>
                  <CardTitle className="text-lg">{faq.question}</CardTitle>
                </CardHeader>
                <CardContent>
                  <p className="text-muted-foreground">{faq.answer}</p>
                </CardContent>
              </Card>
            ))}
          </div>
        </div>
      </section>

      {/* CTA Section */}
      <section className="py-20 px-4 bg-primary text-primary-foreground">
        <div className="container mx-auto text-center">
          <div className="max-w-3xl mx-auto space-y-8">
            <h2 className="text-3xl md:text-4xl font-bold">
              Ready to Start Earning?
            </h2>
            <p className="text-xl opacity-90">
              Join thousands of connection masters already building wealth through their networks.
            </p>
            <div className="flex flex-col sm:flex-row gap-4 justify-center">
              <Button size="lg" variant="secondary" asChild>
                <Link href="/auth/register">
                  Get Started Free
                  <ArrowRight className="ml-2 h-5 w-5" />
                </Link>
              </Button>
              <Button 
                size="lg" 
                variant="outline" 
                className="border-primary-foreground text-primary-foreground hover:bg-primary-foreground hover:text-primary" 
                asChild
              >
                <Link href="/contact">
                  Questions? Contact Sales
                </Link>
              </Button>
            </div>
          </div>
        </div>
      </section>
    </MainLayout>
  );
}