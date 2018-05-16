# See bottom of file for license and copyright information
package Foswiki::Macros::FEATURES_INFO;

use Try::Tiny;
use Data::Dumper;
use Foswiki::FeatureSet qw<getNSFeatures featureMeta featureVersions
  getFSNamespaces>;

use Foswiki::Class -app;
extends qw<Foswiki::Object>;
with qw<Foswiki::Macro>;

sub expand {
    my $this = shift;
    my ( $params, $topicObject ) = @_;

    my $result = "";

    my $mode = $params->{mode} // 'features';
    my $requestedNS = $params->{ns} // $params->{namespace} // undef;

    if ( $mode eq 'features' ) {
        my @nsList =
          $requestedNS eq '*' ? ( "", getFSNamespaces ) : ($requestedNS);

        $result =
"| *Feature* | *Ver.introduced* | *Ver.depracted* | *Ver.obsoleted* | *Description* | *Orig.proposal* | *Documentation topic* |\n";

        foreach my $namespace (@nsList) {

            if ($namespace) {
                $result .=
                    "|  *Namespace: "
                  . Foswiki::entityEncode($namespace)
                  . "*  |||||||\n";
            }

            my @fsList = getNSFeatures($namespace);

            foreach my $feature ( sort @fsList ) {
                my $fsMeta = featureMeta( $feature, -namespace => $namespace );
                my $fsVersions =
                  featureVersions( $feature, -namespace => $namespace );
                my @row;

                push @row, "=$feature=",
                  map { defined $_ ? $_->normal : "" } @$fsVersions;

                push @row,
                  Foswiki::entityEncode( $fsMeta->{"-description"} ) // "";
                push @row,
                  defined( $fsMeta->{"-proposal"} )
                  ? "[[https://foswiki.org/Development/"
                  . $fsMeta->{"-proposal"} . "]["
                  . $fsMeta->{"-proposal"} . "]]"
                  : "";
                push @row, $fsMeta->{"-documentation"} // "";
                $result .= "| " . join( " | ", @row ) . " |\n";
            }
        }
    }
    elsif ( $mode eq 'namespaces' ) {
        my @nsList = getFSNamespaces;
        $result = "\n"
          . join( "",
            map { "   * " . Foswiki::entityEncode($_) . "\n" } @nsList );
    }

    return $result;
}

1;

__END__
Foswiki - The Free and Open Source Wiki, http://foswiki.org/

Copyright (C) 2017 Foswiki Contributors. Foswiki Contributors
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
