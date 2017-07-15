use strict;
use warnings;
use IO::File;
use Text::CSV_XS;
use Data::Dumper;
use DBI;
use DBIx::Custom;
use Encode;
use dbUtil;
use YAML::Syck;
use utf8;


my $conf_file = 'config.yml';
my $dbUtil = dbUtil->new;
my $config = YAML::Syck::LoadFile($conf_file);

$dbUtil->connection($config);

my @files =('worktimes','logintimes','activeworktimes');

for my $file (@files) {
    my $file_path ="$file.csv";

    if ( -f $file_path) {
        my $lines = &load_csv($file_path);
        $dbUtil->set_table($file);
        $dbUtil->delete;
        $dbUtil->insert_bulk($lines);
        $dbUtil->commit_dbh;
    }
}

sub load_csv {

    my ($file) = @_;
    my $io = IO::File->new($file, "r") or die("file not loading");
    #binaryを入れておかないとフィールド内の改行に対応できない
    my $csv = Text::CSV_XS->new();

    #文字コードの判定を行う
    open $io , '<' , $file;
    my $headers;
    my @rows;
    my $count = 0;
    while ( my $items = $csv->getline($io) ) {

       # print Dumper $items;
        if( scalar( @$items) == 0 ) {
            next;
        }

        if ($count == 0) {
            $headers = $items;
        } else {
            my $record;
            for (my $i = 0; $i < scalar(@$headers); $i++) {
                my $name = $headers->[$i];
                my $value = $items->[$i];
                $record->{$name} = $value;
            }
            push(@rows, $record);
        }
        $count++;
    }
    #print Dumper \@rows;
    #ポインタの開放
    $io->close();
    return \@rows;
}

