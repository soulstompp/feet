package Feet::Implantor::Destination::Fey;

use Moose;

use Callusion::Model::Schema;

my $meta = __PACKAGE__->meta();

my %module_attributes = (
                         accounts       => {
					    class => 'Callusion::Model::Account', 
                                            initial_values => [
                                                               {
                                                                number   => 1234567890,
                                                                creation_time => '2009-05-23 00:00:00',
                                                                activation_time => '2009-05-24 00:00:00',
                                                                pin => '12345',
                                                               },
                                                              ],
                                            updated_values => [
                                                               {
                                                                number   => 1234567891,
                                                                creation_time => '2009-05-19 00:00:00',
                                                                activation_time => '2009-05-22 00:00:00',
                                                                pin => '2345',
                                                               },
                                                              ],
                                           },
                        account_credits => { 
                                            class => 'Callusion::Model::AccountCredit', 
                                                            initial_values => [
                                                                               {
                                                                                type_id     => 1, 
                                                                                credit_date => '2009-06-06', 
                                                                                value       => 5.16
                                                                               },
                                                                               {
                                                                                type_id     => 1, 
                                                                                credit_date => '2009-06-07', 
                                                                                value       => 1.19
                                                                               },
                                                                               {
                                                                                type_id     => 1, 
                                                                                credit_date => '2009-06-08', 
                                                                                value       => 2.49
                                                                               },
                                                                               {
                                                                                type_id     => 1, 
                                                                                credit_date => '2009-06-09', 
                                                                                value       => 35.01
                                                                               },
                                                                              ],
                                                            updated_values => [
                                                                               {
                                                                                type_id     => 2, 
                                                                                credit_date => '2009-07-01', 
                                                                                value       => 8.88
                                                                               },
                                                                               {
                                                                                type_id     => 1, 
                                                                                credit_date => '2009-06-02', 
                                                                                value       => 8.46
                                                                               },
                                                                               {
                                                                                type_id     => 1, 
                                                                                credit_date => '2009-06-03', 
                                                                                value       => 0.06
                                                                               },
                                                                               {
                                                                                type_id     => 1, 
                                                                                credit_date => '2009-06-04', 
                                                                                value       => 2.13
                                                                               },
                                                                              ],
                                          },
                        account_credit_types => { 
                                            class => 'Callusion::Model::AccountCreditType', 
                                                            initial_values => [
                                                                               {
                                                                                name       => 'test', 
                                                                               },
                                                                              ],
                                                            updated_values => [
                                                                               {
                                                                                name       => 'test', 
                                                                               },
                                                                              ],
                                                 },
                        brands         => {
					   class => 'Callusion::Model::Brand', 
                                                            initial_values => [
                                                                               {
                                                                                name             => 'test',
                                                                                language         => 'es',
                                                                                incremental      => 1,
                                                                                mark_up          => '5.000',
                                                                                service_fee      => '0.14',
                                                                                service_fee_days => 5,
                                                                               },
                                                                              ],
                                                            updated_values => [
                                                                               {
                                                                                name             => 'test1',
                                                                                language         => 'en',
                                                                                incremental      => 2,
                                                                                mark_up          => '3.320',
                                                                                service_fee      => '0.15',
                                                                                service_fee_days => 3,
                                                                               }
                                                                              ],
                                          },
                      
has schema_class => (isa => 'Str', is => 'ro', required => 1);

has schema => (isa => 'Fey::Schema', is => 'ro', lazy => 1, builder => '_build_schema');

sub BUILD {
    my ($self) = @_;

    for my $module_name (keys %module_attributes) {
        print "adding attribute for $module_name\n";
        my $class_name = $module_attributes{$module_name}->{'class'};
        $meta->add_attribute(
                             $module_name, 
                             isa => "ArrayRef[$class_name]", 
                             is => 'rw', 
                             lazy => 1, 
                             builder => "_build_$module_name",
                             clearer => "_clear_$module_name", 
                             predicate => "_has_$module_name", 
                            );
        print "making attribute for $module_name";
        $meta->add_method( "_build_$module_name" => sub { my $self = shift; $self->_build_objects($module_name); } ); 
    }
}

sub _build_schema {
    my ($self) = @_;

    my $schema = $self->schema_class()->Schema();

    return $schema;
}

sub _build_objects {
    my ($self) = @_;
    my @tables = $self->schema()->tables(qw(accounts account_credits account_credit_types brands));
}

sub _build_record_set {
    my ($self, $table) = @_;

    my @foreign_keys = $table->schema()->foreign_keys_for_table($table);

    my @sources;

    my @target_keys;

    for my $foreign_key (@foreign_keys) {
        my $source_table = $foreign_key->source_table();
        my $target_table = $foreign_key->target_table();

        next unless $source_table->name() eq $table_name;

        push @target_keys, $foreign_key;

        printf "source table: %s	target table: %s\n", $source_table->name(), $target_table->name(); 

        my $name = $target_table->name();
        print "making attribute for $name\n";
        my $target_attribute = $attributes{$target_table->name()};
        print "making attribute source\n";
        my $target_reader = $target_attribute->get_read_method();

        print "calling source_reader(): $target_reader\n";

        push @sources, $self->$target_reader();
    }

    for my $initial_value_set (@{$module_attributes{$table_name}->{'initial_values'}}) {
        for my $initial_values ( $initial_value_set ) {
            my %initial_values = %{$initial_values};   

            for my $foreign_key (@target_keys) {
                my $target_table = $foreign_key->target_table();
                my @column_pairs_set = $foreign_key->column_pairs();

                my $target_table_name = $target_table->name();

                my $target_object = $self->$target_table_name()->[0];

                for my $column_pairs_set (@column_pairs_set) {
                    for my $column_pairs (@$column_pairs_set) {
                        my ($source_column, $target_column) = @$column_pairs;

                        my $source_column_name = $source_column->name();
                        my $target_column_name = $target_column->name();

                        $initial_values{$source_column->name()} = $target_object->$target_column_name(); 
                    }
                }
            }

            my $new_object = undef;

            if ($new_object = $class_name->new(%initial_values)) {
                $new_object->update(%initial_values);        
            }
            else {
                $new_object = $class_name->insert(%initial_values);
            }
        
            push(@objects, $new_object);
        }
    }

    #this should return an iterator made FromArray        
    return \@objects;
}

sub _delete_objects {
    my ($self, $module_name) = @_;

    my $attribute = $self->meta->get_attribute($module_name);

    return undef unless $attribute;

    my $table = Callusion::Model::Schema->Schema()->table($module_name);

    my $predicate = $attribute->predicate();
    return undef unless $self->$predicate();

    my @foreign_keys = $table->schema()->foreign_keys_for_table($table);

    for my $foreign_key (@foreign_keys) {
        my $source_table = $foreign_key->source_table();
        my $target_table = $foreign_key->target_table();

        next if $target_table->name() ne $table->name();

        $self->_delete_objects($source_table->name());
    }

    for my $object (@{$self->$module_name}) {
        $object->delete();
    }

    my $clearer = $attribute->clearer();
    $self->$clearer();

    return undef;
}

no Fey;
no Moose;
