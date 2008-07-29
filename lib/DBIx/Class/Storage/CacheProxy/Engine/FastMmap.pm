package DBIx::Class::Storage::CacheProxy::Engine::FastMmap;

use parent 'Class::Accessor::Fast';
use Cache::FastMmap;

__PACKAGE__->mk_accessors('cache');

sub new{
    my $class=shift;
    my $self=$class->SUPER::new();
    $self->cache(new Cache::FastMmap(@_));
    return $self;
}

sub _debug{};

sub store_into_table_cache{
	my $self=shift;
	$self->_debug("Appending to table cache");
	my %params=@_;
	my $tables=$params{tables};
	my %tables=map {$_=>1} @$tables;
	my $key=$params{hash};
	# получаем количество закэшированных записей для данной таблицы
	# дописываем новый ключ в конец массива
	# схема:
	# table_cache:sessions -> 10 превращается в 11
	# table_cache_row:sessions:1 -> somekey -> DATA
	# ...
	# table_cache_row:sessions:10 -> somekey -> DATA
	# table_cache_row:sessions:11 -> somekey -> DATA <==== оце ми пишемо
	# для кожної таблиці:
	foreach my $table (keys %tables){
		$self->_debug("=>	$table");
		my $row=$self->cache->get_and_set("table_cache:$table",sub{
		    ( $_[1]||0 )+1
		}
		);
		$self->cache->set("table_cache_row:$table:$row"=>$key);
	}
	$self->cache->set($key=>$params{data});
}

sub clear_table_cache{
	my $self=shift;
	$self->_debug("Clearing table cache");
	my $table=shift; # тільки одня таблиця. боронь мене боже від багатьох таблиць T_T
	my $cache=$self->cache;
	return unless my $array_size=$cache->get("table_cache:$table");
	$self->cache->remove("table_cache:$table");
	foreach my $row (1..$array_size){
		my $data_ptr=$cache->get("table_cache_row:$table:$row");
		$self->_debug("=>	[$row] $data_ptr");
		$cache->remove("table_cache_row:$table:$row");
		$cache->remove("$data_ptr");
	}
	
}

sub get{
    shift->cache->get(@_);
}

1;