#!/usr/bin/perl
package dbUtil;

use strict;
use warnings;
use DBI;
use DBIx::Custom;
use Data::Dumper;
use utf8;

sub new {

    my $class  = shift;
    my $self ={
        @_
    };
       
    bless $self, $class;

}

sub connection {

    my $self = shift;

    my $datasource = $self->{"datasource"};
    my $host       = $self->{"host"};
    my $database   = $self->{"database"};
    my $password   = $self->{"password"};
    my $user       = $self->{"user"};

    my $dbh = DBIx::Custom->connect(
        dsn      =>   "dbi:" . $datasource . ":database=" . $database. ";host=". $host .";port=3306",
        password => $password,
        user     => $user,
        option   => {
           mysql_enable_utf8   => 1,
           AutoCommit          => 0,
           PrintError          => 1,
           RaiseError          => 1,
           ShowErrorStatement  => 1,
           AutoInactiveDestroy => 1
        }
    );

    $self->{dbh} = $dbh;
    $self->{database} = $database;

}

sub set_table {

    my $self = shift;
    my ($table) = @_;

    $self->{table} = $table;
}

###
### 通常のSelect文を発行
###
sub select {

    my $self = shift;

    my ($columns, $where) = @_;

    my $select_hash;
    $select_hash->{table} = $self->{table};
    $select_hash->{column} = (defined($columns)) ? $columns : "*";

    if (defined($where)) {
        $select_hash->{where} = $where;
    }

    my $result;
    $result = $self->{dbh}->select(%$select_hash);

    my @records;
    my $data_hash;

    while (my $row = $result->fetch_hash) {
        push @records, $row;
    }
    $self->query_log;
    return \@records;
}

###
### 通常のcount文を発行
###
sub count {

    my $self = shift;

    my ($where) = @_;

    my $select_hash;
    $select_hash->{table} = $self->{table};

    if (defined($where)) {
        $select_hash->{where} = $where;
    }

    my $result;
    $result = $self->{dbh}->count(%$select_hash);
    $self->query_log;
    return $result;
}

###
### SQLのログを取得
###
sub query_log {

    my $self     = shift;
    my $last_sql = $self->{dbh}->last_sql;
    print Dumper $last_sql;

}

###
### プライマリキーで取得
###
sub read {

    my $self  = shift;
    my ($id)  = @_;
    my $table = $self->{table};

    if (!defined($id)) {
        die("undefined id");
    }

    my $record = $self->{dbh}->select(
        table => $table,
        where => {
            id         => $id,
            delete_flg => 0
        }
    )->fetch_hash_one;
    $self->query_log;
    return $record;

}

sub insert {

    my $self = shift;
    my ($hash) = @_;

    my $table = $self->{table};

    my $result = $self->{dbh}->insert($hash, table => $table);
    $self->query_log;
    if ($result) {
        return $self->{dbh}->last_insert_id($self->{database}, $self->{database}, $table, "id");
    }
}


sub delete {

    my $self = shift;
    my ($where) = @_;

    my $table = $self->{table};

    if ($where) {
        $self->{dbh}->delete(where => $where, table => $table);
    } else {
        $self->{dbh}->delete_all(table => $table);
    }

    $self->query_log;
}

sub insert_bulk {
    my $self = shift;
    my ($arr) = @_;
    my $table = $self->{table};

    my $res = $self->{dbh}->insert($arr, table => $table, bulk_insert => 1);
    $self->query_log;
    return $res;
}

sub commit_dbh{
    my $self = shift;
    $self->{dbh}->commit;
}
1;
