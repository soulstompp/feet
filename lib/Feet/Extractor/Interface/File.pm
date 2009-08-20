package Feet::Extractor::Interface::File;

use Moose::Role;

use IO::File;

requires '_parse';
#TODO: give this a better name
#requires '_values';

# TODO: you might want to add this to a file role, require a parse and a write function when implementing the role
has file => ( 
               isa => 'IO::File', 
               is => 'ro', 
               is => 'rw',
               builder => '_build_file',
               handles => {
                           '_get_lines' => 'getlines'
                          }
             );

has file_name => (isa => 'Str', is => 'rw', required => 1 );

has new_file => ( isa => 'Bool', is => 'rw', default => 0 );

has lines => ( isa => 'ArrayRef[Str]', is => 'rw', builder => '_build_lines' );

has objects => (isa => 'ArrayRef[Config::ObjectFile::Config::Object]', is => 'ro', lazy => 1, builder = '_build_objects');

sub BUILD {
    my ($self) = @_;

    $self->file();
    
    return undef;
}

sub _build_file {
    my ($self) = @_;

    my $file = IO::File->new();

    printf "opening file %s for reading\n", $self->file_name();   
 
    if ($file->open($self->file_name())) {
        return $file;
    }
    else {
        die "unable to open file: $!" unless $self->new_file();
        #TODO: try to make the file
    }
}

sub _build_lines {
    my ($self) = @_;

    my @lines = grep { $_ =~ /^[^#;]\w+/ } $self->_get_lines();

    map { $_ =~ s/\s\z//g} @lines;

    return \@lines;
}

1;
