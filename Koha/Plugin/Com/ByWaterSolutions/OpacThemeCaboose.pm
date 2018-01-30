package Koha::Plugin::Com::ByWaterSolutions::OpacThemeCaboose;

## It's good practive to use Modern::Perl
use Modern::Perl;

## Required for all plugins
use base qw(Koha::Plugins::Base);

# This block allows us to load external modules stored within the plugin itself
# In this case it's Template::Plugin::Filter::Minify::JavaScript/CSS and deps
# cpanm --local-lib=. -f Template::Plugin::Filter::Minify::CSS from asssets dir
BEGIN {
    use Config;
    use C4::Context;

    my $pluginsdir = C4::Context->config('pluginsdir');
    my $plugin_libs = '/Koha/Plugin/Com/ByWaterSolutions/OpacThemeCaboose/lib/perl5';
    my $local_libs = "$pluginsdir/$plugin_libs";

    unshift( @INC, $local_libs );
    unshift( @INC, "$local_libs/$Config{archname}" );
}

## Here we set our plugin version
our $VERSION = "{VERSION}";

our $metadata = {
    name            => 'Caboose OPAC Theme plugin',
    author          => 'Kyle M Hall',
    description     => 'Install the Caboose OPAC theme ( design by Michael Cabus )',
    date_authored   => '2018-01-29',
    date_updated    => '1900-01-01',
    minimum_version => '16.05',
    maximum_version => undef,
    version         => $VERSION,
};

sub new {
    my ( $class, $args ) = @_;

    ## We need to add our metadata here so our base class can access it
    $args->{'metadata'} = $metadata;
    $args->{'metadata'}->{'class'} = $class;

    ## Here, we call the 'new' method for our base class
    ## This runs some additional magic and checking
    ## and returns our actual $self
    my $self = $class->SUPER::new($args);

    return $self;
}

sub configure {
    my ( $self, $args ) = @_;
    my $cgi = $self->{'cgi'};

    unless ( $cgi->param('save') ) {
        my $template = $self->get_template( { file => 'configure.tt' } );

        my $dbh = C4::Context->dbh;
        my $query = q{SELECT * FROM plugin_data WHERE plugin_class = 'Koha::Plugin::Com::ByWaterSolutions::OpacThemeCaboose'};
        my $sth = $dbh->prepare( $query );
        $sth->execute();
        my $data;
        while ( my $r = $sth->fetchrow_hashref ) {
            $data->{ $r->{plugin_key} } = $r->{plugin_value}
        }

        $template->param(%$data);

        print $cgi->header(
            {
                -type     => 'text/html',
                -charset  => 'UTF-8',
                -encoding => "UTF-8"
            }
        );
        print $template->output();
    }
    else {
        my $data = { $cgi->Vars };
        delete $data->{ $_ } for qw( method save class );

        $self->store_data($data);

        $self->update_opacheader($data);
        $self->update_opaccredits($data);

        $self->go_home();
    }
}

## This is the 'install' method. Any database tables or other setup that should
## be done when the plugin if first installed should be executed in this method.
## The installation method should always return true if the installation succeeded
## or false if it failed.
sub install() {
    my ( $self, $args ) = @_;

    return 1;
}

## This method will be run just before the plugin files are deleted
## when a plugin is uninstalled. It is good practice to clean up
## after ourselves!
sub uninstall() {
    my ( $self, $args ) = @_;
}


sub update_opacheader {
    my ($self, $data) = @_;

    my $opacheader = C4::Context->preference('opacheader');
    $opacheader =~ s/\n*<!-- JS and CSS for Koha Caboose OPAC Theme Plugin.*End of JS and CSS for Koha Caboose OPAC Theme Plugin -->//gs;

    my $template = $self->get_template( { file => 'opacheader.tt' } );
    $template->param(%$data);

    my $template_output = $template->output();

    $template_output = qq|\n<!-- JS and CSS for Koha Caboose OPAC Theme Plugin 
   This JS was added automatically by installing the Koha Caboose OPAC Theme Plugin
   Please do not modify -->|
      . $template_output
      . q|<!-- End of JS and CSS for Koha Caboose OPAC Theme Plugin -->|;

    $opacheader .= $template_output;
    C4::Context->set_preference( 'opacheader', $opacheader );
}

sub update_opaccredits {
    my ($self, $data) = @_;

    my $opaccredits = C4::Context->preference('opaccredits');
    $opaccredits =~ s/\n*<!-- JS and CSS for Koha Caboose OPAC Theme Plugin.*End of JS and CSS for Koha Caboose OPAC Theme Plugin -->//gs;

    my $template = $self->get_template( { file => 'opaccredits.tt' } );
    $template->param(%$data);

    my $template_output = $template->output();

    $template_output = qq|\n<!-- JS and CSS for Koha Caboose OPAC Theme Plugin 
   This JS was added automatically by installing the Koha Caboose OPAC Theme Plugin
   Please do not modify -->|
      . $template_output
      . q|<!-- End of JS and CSS for Koha Caboose OPAC Theme Plugin -->|;

    $opaccredits .= $template_output;
    C4::Context->set_preference( 'opaccredits', $opaccredits );
}

1;
