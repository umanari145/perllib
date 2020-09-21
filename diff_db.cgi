#!/usr/bin/perl
use strict;
use warnings;
use utf8;

use Carp;
use DBI;
use Dao::DBI;
use SQL::Translator;
use SQL::Translator::Diff;

print "Content-type: text/html\n\n";

my $from_db = "";
my $to_db   = "";

print "Content-type: text/html\n\n";
#ここが起点となるデータベースのDBI
my $from_dbh = DBI->connect("dbi:mysql:$from_db:$db_host", $db_user, $db_pass, {
    PrintError => 0,
    RaiseError => 1,
    AutoCommit => 0,
    mysql_enable_utf8 => 1,
});
#これが目標となるデータベースのDBI
my $dbh_to = DBI->connect("dbi:mysql:$to_db:133.18.31.45", "wms", "wms99", {
    PrintError => 0,
    RaiseError => 1,
    AutoCommit => 0,
    mysql_enable_utf8 => 1,
});

#print Util->vardump( $dbh );

my $from = SQL::Translator->new(
    parser => 'DBI',
    parser_args =>{ dbh => $from_dbh}
)->translate();

my $to = SQL::Translator->new(
    parser => 'DBI',
    parser_args =>{ dbh => $dbh_to}
)->translate();

#下記コマンドで差分のSQLを一気に発行できます。
my $diff = SQL::Translator::Diff->new({
    output_db   => 'MySQL',
    target_schema => $to ,
    source_schema => $from
})->compute_differences->produce_diff_sql;

print $diff;

#そのあとリダイレクトでテキストファイルに出力し下記コマンドを打てばAUTO_INCREMENTが消える
# sed -i -e 's/AUTO_INCREMENT=[0-9]\+//' diff.text