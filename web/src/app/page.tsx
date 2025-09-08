import { MainLayout } from '@/components/layout/main-layout';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { formatCurrency } from '@/lib/utils';
import { PACK_TYPES, SUPPORT_PHONE } from '@/lib/constants';
import Link from 'next/link';
import {
  ArrowRight,
  Shield,
  Users,
  DollarSign,
  MapPin,
  Smartphone,
  Globe,
  Zap,
  CheckCircle,
  Star,
  TrendingUp,
  Lock,
} from 'lucide-react';

const features = [
  {
    icon: Users,
    title: 'Relationship Monetization',
    description: 'Transform your network into passive income with blockchain-verified referrals.',
  },
  {
    icon: Shield,
    title: 'Institutional Security',
    description: 'Enterprise-grade protection with multi-signature treasury and KYC/AML compliance.',
  },
  {
    icon: MapPin,
    title: 'POC Check-ins',
    description: 'Get rewarded for physical networking activities at registered locations.',
  },
  {
    icon: DollarSign,
    title: 'Multi-Level Commissions',
    description: 'Earn from every level of your network with transparent blockchain tracking.',
  },
  {
    icon: Smartphone,
    title: 'Accessibility First',
    description: 'QR code onboarding and SMS verification for all demographics.',
  },
  {
    icon: Globe,
    title: 'Global Reach',
    description: 'Multi-currency support with traditional and crypto payment options.',
  },
];

const stats = [
  { value: '9.5M', label: 'Target Market Size' },
  { value: '$2.85M', label: 'System Value' },
  { value: '98/100', label: 'Security Score' },
  { value: '24/7', label: 'Support Available' },
];

const testimonials = [
  {
    name: 'Sarah Johnson',
    role: 'Former Sales Director',
    content: 'After being laid off, Digital Giant helped me turn my 2,000+ LinkedIn connections into $8K/month in passive income.',
  },
  {
    name: 'Mike Rodriguez',
    role: 'Real Estate Professional',
    content: 'The POC beacon system at open houses generates $500/week additional income. Game changer!',
  },
  {
    name: 'Jennifer Chen',
    role: 'HR Executive',
    content: 'We use Digital Giant to help our laid-off employees monetize their networks. Positive impact all around.',
  },
];

export default function HomePage() {
  return (
    <MainLayout>
      {/* Hero Section */}
      <section className="relative py-20 md:py-32 px-4 bg-gradient-to-b from-primary/5 to-background">
        <div className="container mx-auto text-center">
          <div className="max-w-4xl mx-auto space-y-8">
            <h1 className="text-4xl md:text-6xl font-bold tracking-tight">
              Where Connections Become{' '}
              <span className="text-primary">Currency</span>
            </h1>
            <p className="text-xl md:text-2xl text-muted-foreground max-w-3xl mx-auto">
              For every laid-off professional, displaced broker, and networking expert - 
              this is YOUR platform to transform relationships into generational wealth.
            </p>
            <div className="flex flex-col sm:flex-row gap-4 justify-center items-center">
              <Button size="lg" className="text-lg px-8 py-6" asChild>
                <Link href="/auth/register">
                  Get Started Free
                  <ArrowRight className="ml-2 h-5 w-5" />
                </Link>
              </Button>
              <Button size="lg" variant="outline" className="text-lg px-8 py-6" asChild>
                <Link href="/features">
                  Learn More
                </Link>
              </Button>
            </div>
            <div className="flex items-center justify-center space-x-4 text-sm text-muted-foreground">
              <div className="flex items-center space-x-1">
                <CheckCircle className="h-4 w-4 text-green-500" />
                <span>No credit card required</span>
              </div>
              <div className="flex items-center space-x-1">
                <CheckCircle className="h-4 w-4 text-green-500" />
                <span>Setup in 2 minutes</span>
              </div>
              <div className="flex items-center space-x-1">
                <CheckCircle className="h-4 w-4 text-green-500" />
                <span>24/7 Support: {SUPPORT_PHONE}</span>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Stats Section */}
      <section className="py-16 bg-muted/30">
        <div className="container mx-auto px-4">
          <div className="grid grid-cols-2 md:grid-cols-4 gap-8">
            {stats.map((stat, index) => (
              <div key={index} className="text-center">
                <div className="text-3xl md:text-4xl font-bold text-primary">
                  {stat.value}
                </div>
                <div className="text-sm text-muted-foreground mt-2">
                  {stat.label}
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Features Section */}
      <section className="py-20 px-4">
        <div className="container mx-auto">
          <div className="text-center space-y-4 mb-16">
            <h2 className="text-3xl md:text-4xl font-bold">
              Built for Connection Masters
            </h2>
            <p className="text-xl text-muted-foreground max-w-2xl mx-auto">
              While others build algorithms to replace relationships, we build technology to amplify them.
            </p>
          </div>
          
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
            {features.map((feature, index) => {
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

      {/* Pricing Preview */}
      <section className="py-20 px-4 bg-muted/30">
        <div className="container mx-auto">
          <div className="text-center space-y-4 mb-16">
            <h2 className="text-3xl md:text-4xl font-bold">
              Start Building Your Empire
            </h2>
            <p className="text-xl text-muted-foreground">
              Choose the pack that fits your ambition
            </p>
          </div>
          
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8 max-w-5xl mx-auto">
            {Object.entries(PACK_TYPES).map(([key, pack]) => (
              <Card key={key} className="relative h-full">
                {key === 'PROFESSIONAL' && (
                  <div className="absolute -top-4 left-1/2 transform -translate-x-1/2">
                    <span className="bg-primary text-primary-foreground px-4 py-1 rounded-full text-sm font-medium">
                      Most Popular
                    </span>
                  </div>
                )}
                <CardHeader className="text-center">
                  <CardTitle className="text-2xl">{pack.name}</CardTitle>
                  <div className="text-4xl font-bold text-primary">
                    {formatCurrency(pack.price)}
                  </div>
                  <CardDescription>
                    {Math.round(pack.margin * 100)}% commission rate
                  </CardDescription>
                </CardHeader>
                <CardContent className="space-y-4">
                  <ul className="space-y-2">
                    {pack.features.map((feature, index) => (
                      <li key={index} className="flex items-center space-x-2">
                        <CheckCircle className="h-4 w-4 text-green-500 flex-shrink-0" />
                        <span className="text-sm">{feature}</span>
                      </li>
                    ))}
                  </ul>
                  <Button className="w-full" variant={key === 'PROFESSIONAL' ? 'default' : 'outline'}>
                    Get Started
                  </Button>
                </CardContent>
              </Card>
            ))}
          </div>
          
          <div className="text-center mt-12">
            <Button variant="outline" size="lg" asChild>
              <Link href="/pricing">
                View Full Pricing Details
                <ArrowRight className="ml-2 h-4 w-4" />
              </Link>
            </Button>
          </div>
        </div>
      </section>

      {/* Testimonials */}
      <section className="py-20 px-4">
        <div className="container mx-auto">
          <div className="text-center space-y-4 mb-16">
            <h2 className="text-3xl md:text-4xl font-bold">
              Success Stories
            </h2>
            <p className="text-xl text-muted-foreground">
              Real people, real results, real transformation
            </p>
          </div>
          
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            {testimonials.map((testimonial, index) => (
              <Card key={index}>
                <CardContent className="pt-6">
                  <div className="flex mb-4">
                    {[...Array(5)].map((_, i) => (
                      <Star key={i} className="h-4 w-4 fill-primary text-primary" />
                    ))}
                  </div>
                  <p className="text-muted-foreground mb-4">
                    "{testimonial.content}"
                  </p>
                  <div>
                    <div className="font-semibold">{testimonial.name}</div>
                    <div className="text-sm text-muted-foreground">{testimonial.role}</div>
                  </div>
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
              Ready to Build Your Digital Empire?
            </h2>
            <p className="text-xl opacity-90">
              Join thousands of connection masters who are already transforming their networks into wealth.
            </p>
            <div className="flex flex-col sm:flex-row gap-4 justify-center">
              <Button size="lg" variant="secondary" className="text-lg px-8 py-6" asChild>
                <Link href="/auth/register">
                  Start Free Today
                  <ArrowRight className="ml-2 h-5 w-5" />
                </Link>
              </Button>
              <Button 
                size="lg" 
                variant="outline" 
                className="text-lg px-8 py-6 border-primary-foreground text-primary-foreground hover:bg-primary-foreground hover:text-primary" 
                asChild
              >
                <Link href="/contact">
                  Talk to Sales
                </Link>
              </Button>
            </div>
          </div>
        </div>
      </section>
    </MainLayout>
  );
}
