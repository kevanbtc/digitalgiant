import { Metadata } from 'next';
import { MainLayout } from '@/components/layout/main-layout';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import Link from 'next/link';
import {
  Users,
  Target,
  Heart,
  Lightbulb,
  Shield,
  TrendingUp,
  Globe,
  Zap,
} from 'lucide-react';

export const metadata: Metadata = {
  title: 'About Us',
  description: 'Learn about Digital Giant\'s mission to empower connection masters and transform relationships into generational wealth.',
};

const values = [
  {
    icon: Heart,
    title: 'Relationships First',
    description: 'We believe human connections are invaluable and irreplaceable.',
  },
  {
    icon: Shield,
    title: 'Trust & Security',
    description: 'Enterprise-grade security and transparency in every transaction.',
  },
  {
    icon: Users,
    title: 'Community Driven',
    description: 'Built by connectors, for connectors, with community at our core.',
  },
  {
    icon: TrendingUp,
    title: 'Generational Wealth',
    description: 'Creating sustainable income opportunities for families.',
  },
];

const team = [
  {
    name: 'The Visionaries',
    role: 'Founding Team',
    description: 'Former sales professionals, displaced brokers, and networking experts who understand the value of relationships.',
  },
  {
    name: 'Tech Innovators',
    role: 'Development Team',
    description: 'Blockchain experts and Full-stack developers building the future of the connection economy.',
  },
  {
    name: 'Community Leaders',
    role: 'Success Team',
    description: 'Dedicated professionals helping connection masters maximize their potential.',
  },
];

const milestones = [
  {
    year: '2023',
    title: 'Concept Born',
    description: 'Founded during the great tech layoffs to help displaced professionals monetize their networks.',
  },
  {
    year: '2024',
    title: 'Platform Development',
    description: 'Built enterprise-grade infrastructure with $2.85M equivalent development value.',
  },
  {
    year: '2025',
    title: 'Market Launch',
    description: 'Targeting 9.5M displaced professionals with revolutionary connection monetization.',
  },
  {
    year: '2026+',
    title: 'Global Expansion',
    description: 'Becoming the standard for relationship-based digital economies worldwide.',
  },
];

export default function AboutPage() {
  return (
    <MainLayout>
      {/* Hero Section */}
      <section className="py-20 md:py-32 px-4 bg-gradient-to-b from-primary/5 to-background">
        <div className="container mx-auto text-center">
          <div className="max-w-4xl mx-auto space-y-8">
            <h1 className="text-4xl md:text-6xl font-bold tracking-tight">
              Building the{' '}
              <span className="text-primary">Connection Economy</span>
            </h1>
            <p className="text-xl md:text-2xl text-muted-foreground max-w-3xl mx-auto">
              In an era of mass layoffs and AI disruption, Digital Giant creates a second chance economy 
              for relationship builders. We transform human connections into generational wealth.
            </p>
            <div className="flex flex-col sm:flex-row gap-4 justify-center">
              <Button size="lg" asChild>
                <Link href="/auth/register">Join Our Mission</Link>
              </Button>
              <Button size="lg" variant="outline" asChild>
                <Link href="/contact">Contact Us</Link>
              </Button>
            </div>
          </div>
        </div>
      </section>

      {/* Mission Section */}
      <section className="py-20 px-4">
        <div className="container mx-auto">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-16 items-center">
            <div className="space-y-6">
              <h2 className="text-3xl md:text-4xl font-bold">Our Mission</h2>
              <div className="text-lg text-muted-foreground space-y-4">
                <p>
                  To every sales professional who's been told "we're going digital"
                  <br />
                  To every broker who's watched algorithms replace relationships  
                  <br />
                  To every networking expert whose events got "optimized away"
                </p>
                <p className="font-semibold text-foreground">
                  Your connections aren't outdated - they're INVALUABLE.
                  <br />
                  Your relationships aren't replaceable - they're your GOLDMINE.
                  <br />
                  Your network isn't obsolete - it's your SUPERPOWER.
                </p>
              </div>
            </div>
            <div className="space-y-6">
              <div className="bg-primary/10 p-8 rounded-2xl">
                <div className="text-center space-y-4">
                  <Target className="h-16 w-16 text-primary mx-auto" />
                  <h3 className="text-2xl font-bold">9.5M Professionals</h3>
                  <p className="text-muted-foreground">
                    Our target market of displaced professionals seeking opportunity
                  </p>
                  <div className="grid grid-cols-2 gap-4 text-sm">
                    <div>
                      <div className="font-semibold">2.1M</div>
                      <div className="text-muted-foreground">Sales Professionals</div>
                    </div>
                    <div>
                      <div className="font-semibold">850K</div>
                      <div className="text-muted-foreground">Real Estate Agents</div>
                    </div>
                    <div>
                      <div className="font-semibold">420K</div>
                      <div className="text-muted-foreground">Insurance Brokers</div>
                    </div>
                    <div>
                      <div className="font-semibold">4.8M</div>
                      <div className="text-muted-foreground">Service Workers</div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Values Section */}
      <section className="py-20 px-4 bg-muted/30">
        <div className="container mx-auto">
          <div className="text-center space-y-4 mb-16">
            <h2 className="text-3xl md:text-4xl font-bold">Our Values</h2>
            <p className="text-xl text-muted-foreground max-w-2xl mx-auto">
              The principles that guide everything we do
            </p>
          </div>
          
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-8">
            {values.map((value, index) => {
              const Icon = value.icon;
              return (
                <Card key={index} className="text-center h-full">
                  <CardHeader>
                    <div className="w-16 h-16 bg-primary/10 rounded-xl flex items-center justify-center mx-auto mb-4">
                      <Icon className="h-8 w-8 text-primary" />
                    </div>
                    <CardTitle className="text-xl">{value.title}</CardTitle>
                  </CardHeader>
                  <CardContent>
                    <CardDescription className="text-base">
                      {value.description}
                    </CardDescription>
                  </CardContent>
                </Card>
              );
            })}
          </div>
        </div>
      </section>

      {/* Story Section */}
      <section className="py-20 px-4">
        <div className="container mx-auto">
          <div className="max-w-4xl mx-auto">
            <div className="text-center space-y-4 mb-16">
              <h2 className="text-3xl md:text-4xl font-bold">Our Story</h2>
              <p className="text-xl text-muted-foreground">
                Born from necessity, built with purpose
              </p>
            </div>
            
            <div className="space-y-16">
              {milestones.map((milestone, index) => (
                <div key={index} className="flex flex-col md:flex-row gap-8 items-center">
                  <div className="flex-shrink-0">
                    <div className="w-20 h-20 bg-primary text-primary-foreground rounded-full flex items-center justify-center text-xl font-bold">
                      {milestone.year}
                    </div>
                  </div>
                  <div className="flex-1 text-center md:text-left">
                    <h3 className="text-2xl font-bold mb-2">{milestone.title}</h3>
                    <p className="text-lg text-muted-foreground">{milestone.description}</p>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </section>

      {/* Team Section */}
      <section className="py-20 px-4 bg-muted/30">
        <div className="container mx-auto">
          <div className="text-center space-y-4 mb-16">
            <h2 className="text-3xl md:text-4xl font-bold">Our Team</h2>
            <p className="text-xl text-muted-foreground">
              Built by connectors, for connectors
            </p>
          </div>
          
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            {team.map((member, index) => (
              <Card key={index} className="text-center h-full">
                <CardHeader>
                  <div className="w-20 h-20 bg-gradient-to-br from-primary to-primary/60 rounded-full flex items-center justify-center mx-auto mb-4">
                    <Users className="h-10 w-10 text-primary-foreground" />
                  </div>
                  <CardTitle className="text-xl">{member.name}</CardTitle>
                  <CardDescription className="font-medium text-primary">
                    {member.role}
                  </CardDescription>
                </CardHeader>
                <CardContent>
                  <p className="text-muted-foreground">{member.description}</p>
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
              Ready to Join the Revolution?
            </h2>
            <p className="text-xl opacity-90">
              Be part of the movement that's transforming how we value human connections.
            </p>
            <div className="flex flex-col sm:flex-row gap-4 justify-center">
              <Button size="lg" variant="secondary" asChild>
                <Link href="/auth/register">Get Started Today</Link>
              </Button>
              <Button size="lg" variant="outline" className="border-primary-foreground text-primary-foreground hover:bg-primary-foreground hover:text-primary" asChild>
                <Link href="/features">Explore Features</Link>
              </Button>
            </div>
          </div>
        </div>
      </section>
    </MainLayout>
  );
}