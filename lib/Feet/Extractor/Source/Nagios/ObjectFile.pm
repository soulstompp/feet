package Config::ObjectFiles::Config::Extractor::Source::NagiosFiles;

use Moose::Role;

#TODO: make sure this is a role 
with 'Nagios::Config::File';

#this should go into config
my %object_types = (
                    command => 'Nagios::Object::Command', 
                    contact => 'Nagios::Object::Contact', 
                    contact_group => 'Nagios::Object::ContactGroup', 
                    host => 'Nagios::Object::Host', 
                    host_dependency => 'Nagios::Object::HostDependency', 
                    host_escalation => 'Nagios::Object::HostEscalation', 
                    host_group => 'Nagios::Object::HostGroup', 
                    service => 'Nagios::Object::Service', 
                    service_dependency => 'Nagios::Object::ServiceDependency', 
                    service_escalation => 'Nagios::Object::ServiceEscalation', 
                    service_group => 'Nagios::Object::ServiceGroup', 
                    time_period => 'Nagios::Object::TimePeriod', 
                   );

has objects => (isa => 'ArrayRef[Config::ObjectFile::Config::Object]', is => 'ro', lazy => 1, builder = '_build_objects');

sub _build_objects {
    my ($self, @lines) = @_;

    my $object_num = 0;
    my $in_object_block = 0;
    my $total_objects = 0;

    my %tmp_object = ();

    for my $line (@lines) {
        chomp $line;
        next if $line =~ /^#/;

        if ($line =~ /define\s+(.*)\s*{/) {
            $in_object_block = 1;
            %tmp_object = ( type => $1 );
        }
        elsif ($line =~ /\s*}/ && $in_object_block == 1) {
            $object_num++;
            $total_objects++;
            $in_object_block = 0;

            push (@{$object_groups->{$object_group_name}}, {%tmp_object});
        }
        else {
            $line =~ s/^\s//;
            my ($key, $value) = split /\s+/, $line;

            $tmp_object{$key} = $value;
        }
    }
 
    # get the right object type    
    my $object_type = $tmp_object{'type'};
    delete $tmp_object{'type'};
 
    die "unsupported type $object_type given" unless defined $object_classes{$type};

    Class::MOP::load_class($object_classes{$type});

    push @{$self->objects()}, $object_classes{$type}->new(%tmp_object); 
}

