package DBIx::Class::Storage::CacheProxy::Cursor;
use base qw/DBIx::Class::Storage::DBI::Cursor/;


=head1 NAME

DBIx::Class::Storage::CacheProxy::Cursor

=head1 DESCRIPTION

Cursor class for CahceProxy. See DBIx::Class::Storage::CacheProxy::Cursor

=cut

=head2 METHODS

=head2 all

=cut

sub all {
    my $self = shift;
    my @args=@_;
    my $tables=[values %{$self->{attrs}{from}[0]}];
    $self->{storage}->_cache_proxy($self->{attrs},$tables, sub{
	$self->SUPER::all(@args);
    });
}

=head2 next

=cut

sub next {
    my $self = shift;
    my $tables=[values %{$self->{attrs}{from}[0]}];
    my @args=@_;
    $self->{storage}->_cache_proxy(
                      [
                        attrs     => $self->{attrs},
                        position  => $self->{pos},
                        wantarray => wantarray
                      ],$tables,sub{
		      	$self->SUPER::next(@args);
		      }
    );
}

=head1 AUTHOR

Andrey Kostenko <andrey@kostenko.name>

=head1 SEE ALSO

DBIx::Class::Storage::CacheProxy

=cut

1;
