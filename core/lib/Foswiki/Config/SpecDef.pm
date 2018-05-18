# See bottom of file for license and copyright information

=begin TML

---+ Class Foswiki::Config::SpecDef

Supporting class for parsing specs data structure.

---++ DESCRIPTION

Object of this class are containers of raw spec data – i.e., of a list

=cut

package Foswiki::Config::SpecDef;

use Foswiki::Exception::Config;

use Foswiki::Class -types;
extends qw(Foswiki::Object);

=begin TML

---++ ATTRIBUTES

=cut

=begin TML

---+++ ObjectAttribute specDef

List of specs.

=cut

has specDef => (
    is       => 'rw',
    required => 1,
    assert   => ArrayRef,
);

=begin TML

---+++ ObjectAttribute cursor

Current position in =specDef=

=cut

has cursor => (
    is      => 'rw',
    default => 0,
);

=begin TML

---+++ ObjectAttribute source

The source of the specs. Could be either string or a =Foswiki::Config::DataHash=
instance.

=cut

has source => (
    is       => 'ro',
    required => 1,
);

=begin TML

---+++ ObjectAttribute section

Current section. An instance of =Foswiki::Config::Section= class.

=cut

has section => (
    is       => 'ro',
    weak_ref => 1,
    assert   => Maybe [ InstanceOf ['Foswiki::Config::Section'] ],
);

=begin TML

---+++ ObjectAttribute keyPath

List of keys forming a path from the root to the current or next added key.

=cut

has keyPath => (
    is      => 'ro',
    default => sub { [] },
);

=begin TML

---+++ ObjectAttribute dataObj

An instance of =Foswiki::Config::DataHash= class.

=cut

has dataObj => ( is => 'rw', );

=begin TML

---+++ ObjectAttribute localData

Boolean, true if the =dataObj= attribute of the object is local; i.e. it doesn't
represent application's config object data.

=cut

has localData => ( is => 'rw', default => 0, );

# Last fetched spec element.
has _lastFetch => ( is => 'rw', );

=begin TML

---++ METHODS

=cut

=begin TML

---+++ ObjectMethod fetch( [ $count ] )

Fetches the next =$count= items from the specs. If argument is omitted then
only one item is fetched.

=cut

sub fetch {
    my $this = shift;

    my $count = @_ ? shift : 1;

    return () unless $count;

    Foswiki::Exception::Config::NoNextDef->throw(
        text => "No more elements in the queue", )
      unless $this->hasNext($count);

    my $cur = $this->cursor;
    my @elems = @{ $this->specDef }[ $cur .. ( $cur + $count - 1 ) ];

    $this->_lastFetch( $elems[-1] );

    $this->cursor( $cur + $count );

    return wantarray ? @elems : ( $count == 1 ? $elems[0] : \@elems );
}

=begin TML

---+++ ObjectMethod count()

Returns a number of unprocessed yet elements in $this->specDef

=cut

sub count {
    my $this = shift;

    return scalar( @{ $this->specDef } ) - $this->cursor;
}

=begin TML

---+++ ObjectMethod hasNext( [ $count ] )

Returns true if there're still =$count= more spec items to fetch. Checks for
a single item if argument is omitted.

=cut

sub hasNext {
    my $this = shift;
    my ($count) = @_ ? shift : 1;

    return @{ $this->specDef } >= ( $this->cursor + $count );
}

=begin TML

---+++ ObjectMethod badSubSpecElem( $element )

Returns undef if element is ok to be used as a subspec. Otherwise returns
error text about element type suitable to be used in a error message.

=cut

sub badSubSpecElem {
    my $this = shift;
    my $elem = shift;
    return (
        defined $elem
        ? (
            ref($elem) eq 'ARRAY'
            ? undef
            : "element of type '" . ( ref($elem) // 'SCALAR' ) . "'"
          )
        : "undefined element"
    );
}

=begin TML

---+++ ObjectMethod subSpecs( %profile )

Create a new =Foswiki::Config::SpecDef= object of the current spec item. The
item has to be an arrayref.

The method is used to parse a section body.

=%profile= will be passed to the sub-specs object constructor.

=cut

sub subSpecs {
    my $this    = shift;
    my %profile = @_;

    my @subProfile;

    unless ( $profile{specDef} ) {
        my $lastElem = $this->_lastFetch;

        my $badElemTxt = $this->badSubSpecElem($lastElem);
        Foswiki::Exception::BadSpecData->throw(
            text => "Cannot create specs definitions list from $badElemTxt" )
          if $badElemTxt;

        push @subProfile,
          specDef => [ ref($lastElem) eq 'HASH' ? %$lastElem : @$lastElem ];
    }

    push @subProfile,
      section => $this->section,
      unless ( $profile{section} );

    push @subProfile,
      dataObj   => $this->dataObj,
      localData => $this->localData,
      if $this->dataObj;

    my $subSpecs = ref($this)->new(
        source => $this->source,
        @subProfile,
        @_,
    );
    return $subSpecs;
}

=begin TML

---+++ ObjectMethod inject( %params )

Insert a list of spec items into current position. The only key of =%params=
supported is =specDef= with arrayref of spec items to be inserted.

Returns _true_ only if =specDef= exists and contains array.

Could be used to insert dynamically generated specs for further processing by
the configuration framework.

=cut

sub inject {
    my $this   = shift;
    my %params = @_;

    return undef
      unless defined $params{specDef} && ref( $params{specDef} ) eq 'ARRAY';

    splice( @{ $this->specDef }, $this->cursor, 0, @{ $params{specDef} } );

    return 1;
}

1;
__END__
Foswiki - The Free and Open Source Wiki, http://foswiki.org/

Copyright (C) 2016 Foswiki Contributors. Foswiki Contributors
are listed in the AUTHORS file in the root of this distribution.
NOTE: Please extend that file, not this notice.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version. For
more details read LICENSE in the root of this distribution.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

As per the GPL, removal of this notice is prohibited.