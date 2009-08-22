package Feet::Extractor::Source::Fey;

use Moose;

with 'Feet::Extractor::Interface::SourceDriver';

use Fey::Meta::Class::Table;
use Fey::Object::Iterator::FromArray;
use Fey::Loader;

use Data::Dumper;
use Feet::Object;

my $meta = __PACKAGE__->meta();

has schema_class => (isa => 'Str', is => 'ro', required => 1);

has schema => (isa => 'Fey::Schema', is => 'ro', lazy => 1, builder => '_build_schema');

sub BUILD {
    my ($self) = @_;

    for my $table ($self->schema()->tables()) {
        my $table_name = $table->name();

        $meta->add_attribute(
                             $table_name,
                             isa => "Fey::ORM::Role::Iterator",
                             is => 'rw',
                             lazy => 1,
                             builder => "_build_$table_name",
                             clearer => "_clear_$table_name",
                             predicate => "_has_$table_name",
                            );

        $meta->add_method( "_build_$table_name" => sub { my $self = shift; $self->_build_record_set($table); } );
    }
}

sub _build_schema {
    my ($self) = @_;

    my $schema = $self->schema_class()->Schema();

    return $schema;
}

sub _extract_objects {
    my ($self) = @_;

    my @tables = $self->schema()->tables();

    my @objects; 

    for my $table (@tables) {
        my $table_name = $table->name();

        print "requesting records for $table_name\n";

        my $records = $self->$table_name();
    }

    return $self->objects();
}

sub _build_record_set {
    my ($self, $table) = @_;

    printf "building table for %s\n", $table->name();

    my $query = $self->schema_class()->SQLFactoryClass()->new_select();
    my $keys_processed = 0;

    my $queried_columns = {};

    for my $column ($table->columns) {
        $queried_columns->{$column->table()->name()}->{$column->name()}->{'column'} = $column; 
        $queried_columns->{$column->table()->name()}->{$column->name()}->{'exclude'} = 0;
    }

    $query->from($table);

    my @query_tables = ($table);

    for my $foreign_key ($self->schema()->foreign_keys_for_table($table)) {
        my $source_table = $foreign_key->source_table();
        my $target_table = $foreign_key->target_table();

        my $source_table_name = $source_table->name();
        my $target_table_name = $target_table->name();        

        next if $target_table->name() eq $table->name();

        my @column_pairs_set = $foreign_key->column_pairs();

        my $pair_sets_processed = 0;

        my $target_records = $self->$target_table_name();

        $target_records->reset();

        my @target_table_rows = map { $_->{$target_table->name()} } $target_records->all_as_hashes();        

        next unless scalar @target_table_rows;

        push @query_tables, $target_table;

        for my $column_pairs_set (@column_pairs_set) {
            for my $column_pairs (@$column_pairs_set) {
                my ($source_column, $target_column) = @$column_pairs;

                my $target_column_name = $target_column->name();

                $queried_columns->{$source_column->table()->name()}->{$source_column->name()}->{exclude} = 1;
                $queried_columns->{$target_column->table()->name()}->{$target_column->name()}->{exclude} = 1;
 
                printf "mapping out on column name: %s\n", $target_column->name(); 
                my @match_values = map { $_->$target_column_name() } @target_table_rows;           

                use Data::Dumper;
                print "match values: " . Dumper \@match_values;

                unless (scalar @match_values) {
                    return Fey::Object::Iterator::FromArray->new( 
                                                                 classes => [ (Fey::Meta::Class::Table->ClassForTable( $table )) ],
                                                                 objects => [],
                                                                ) unless scalar @match_values;
                }

                $query->where('and') if $pair_sets_processed;
                $query->where( $source_column, 'IN', @match_values);

                my @candidate_keys = @{$target_table->candidate_keys()};

                my @identifiers;

                for my $candidate_key_set (@candidate_keys) {
                    my $key_count;
                    my $is_primary_key = 1;

                    my %key_names = map { $_->name() => 1 } @{$candidate_key_set};

                    for my $key_field (@{$target_table->primary_key()}) {
                        printf "testing primary key part %s against %s\n", $key_field->name(), join ",", keys %key_names;
                        $is_primary_key = 0 unless exists $key_names{$key_field->name()} ;
                        print "is still primary: $is_primary_key\n";
                        last unless $is_primary_key;
                    }

                    #TODO: this needs to be added in and I think is a bug.
                    #next if $is_primary_key;

                    for my $candidate_key (@{$candidate_key_set}) {
                        printf "adding identifier %s\n", $candidate_key->name();
                        push @identifiers, $candidate_key;
                       
                        #only included candidate keys should be tested
                        unless (defined $queried_columns->{$candidate_key->table()->name()}->{$candidate_key->name()} 
                            || $queried_columns->{$candidate_key->table()->name()}->{$candidate_key->name()}->{'exclude'}) {
                            $queried_columns->{$candidate_key->table()->name()}->{$candidate_key->name()}->{'exclude'} = $is_primary_key;
                        }
                    }

                }

            }

            $pair_sets_processed++;
        }

        push @query_tables, $target_table;

        $query->from($table, $target_table, $foreign_key); 
        $keys_processed++;
     }

     my @select_columns = ();

     for my $table_name ( keys %{$queried_columns} ) {
          print "extracted table name $table_name from queried_columns\n";
          for my $column_name ( keys %{$queried_columns->{$table_name}} ) {
              print "extracted column name $column_name from queried_columns\n";
              push @select_columns, $queried_columns->{$table_name}->{$column_name}->{'column'};
          }
     } 

     $query->select( @select_columns );

     my $dbh = $self->schema_class->DBIManager()->default_source()->dbh();

     printf "select statement: %s\n", $query->sql($dbh);

     printf "mapping table objects for: %s\n", join ",", map { $_->name() } @query_tables;

     my $record_set = Fey::Object::Iterator::FromSelect::Caching->new(
                                                                      classes     => [ (Fey::Meta::Class::Table->ClassForTable( @query_tables )) ],
                                                                      select      => $query,
                                                                      dbh         => $dbh
                                                                     );
     

     printf "returning %s record set\n", $table->name();

    while (my %record = $record_set->next_as_hash()) {
        my %attributes;

        my $object;

        for my $record_table (keys %record) {
            my $prefix = undef;
            $prefix = "$record_table." if $record_table ne $table->name; 

            print "checking the record table: $record_table and has prefix: $prefix\n";

            my $record = $record{$record_table};

            $object = Feet::Object->new( category => $table->name() ); 

            for my $table_name ( keys %{$queried_columns} ) {
                print "setting up object thingy for table $table_name from queried_columns\n";
                for my $column_name ( keys %{$queried_columns->{$table_name}} ) {
                    print "setting up object thingy for $table_name.$column_name from queried_columns\n";
                    #TODO: check to see if this should be excluded
                    printf "set value to %s\n", $record->$column_name();
                    next if $queried_columns->{$table_name}->{$column_name}->{'exclude'};
                    printf "saving value for %s to %s in object\n", $column_name, $record->$column_name();
                    $object->set_property($column_name => $record->$column_name());
                }
          }
          
        } 


        $self->add_objects($object);   
    }
     #TODO: return a nicely filled out feet::object here not a record set 
     return $record_set;
     #TODO: add the where clause for a time period if applicable 
}

no Fey;
no Moose;

1;
