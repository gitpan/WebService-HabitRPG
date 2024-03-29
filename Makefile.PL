
# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v5.015.
use strict;
use warnings;

use 5.010000;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Perl interface to the HabitRPG API",
  "AUTHOR" => "Paul Fenwick <pjf\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "WebService-HabitRPG",
  "EXE_FILES" => [
    "bin/hrpg"
  ],
  "LICENSE" => "perl",
  "NAME" => "WebService::HabitRPG",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Config::Tiny" => 0,
    "Data::Dumper" => 0,
    "File::Spec" => 0,
    "IO::Handle" => 0,
    "JSON::Any" => 0,
    "LWP::Protocol::https" => 0,
    "Method::Signatures" => 20121201,
    "Moo" => 0,
    "Mozilla::CA" => 0,
    "POSIX" => 0,
    "Scalar::Util" => 0,
    "Try::Tiny" => 0,
    "WWW::Mechanize" => 0,
    "autodie" => 0,
    "constant" => 0,
    "strict" => 0,
    "utf8::all" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "JSON::XS::Boolean" => 0,
    "Test::More" => 0
  },
  "VERSION" => "0.22",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Carp" => 0,
  "Config::Tiny" => 0,
  "Data::Dumper" => 0,
  "File::Spec" => 0,
  "IO::Handle" => 0,
  "JSON::Any" => 0,
  "JSON::XS::Boolean" => 0,
  "LWP::Protocol::https" => 0,
  "Method::Signatures" => 20121201,
  "Moo" => 0,
  "Mozilla::CA" => 0,
  "POSIX" => 0,
  "Scalar::Util" => 0,
  "Test::More" => 0,
  "Try::Tiny" => 0,
  "WWW::Mechanize" => 0,
  "autodie" => 0,
  "constant" => 0,
  "strict" => 0,
  "utf8::all" => 0,
  "warnings" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



