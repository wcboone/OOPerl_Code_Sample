
use strict;
use warnings;

package GSI::DataX::GNC::Report::MissingImage;
our $VERSION = 1.00;

use GSI::DataTranslate::Simple;
use GSI::DataX::GNC::Report::MissingImage::Files::Local;
use Carp;

warn "Loaded ", __PACKAGE__,"\n" if (GSI::Utils::Verbose->get_level() > 2);

sub _get_add_sql
{
  my ($self ,$list_of_columns) = @_;
  my $binds   = join( ", ", (map { '?' } @$list_of_columns));

my $sql = <<"END_SQL";
select   distinct 
         ce.catalog_entry_id  "PID"
        ,gs.sku               "SKU"
        ,ce.status            "PID status"
        ,ce2.title            "Global Category Name"
        ,ce.global_cat_id     "Global Category ID"
        ,ce.long_title        "Product Long Title"
        ,nvl(i.file_url,'NO') "Label Status" 
        ,gs.jda_style         "MFG Style Code"
FROM catalog_entry ce
join catalog_entry ce2 on ( ce.global_cat_id = ce2.catalog_entry_id)
join store_product sp  on ( sp.product_id = ce.catalog_entry_id 
                            and sp.store_code = ? ) 
join product_sku ps on ( ps.product_id = ce.catalog_entry_id)
join gsi_sku gs     on ( ps.sku  =  gs.sku 
                         and substr(gs.jda_dept,0,3) in ( '816') 
                        ) 
left join catalog_image ci on ( ci.catalog_entry_id = ce.catalog_entry_id
                         and  ci.element_type in ( $binds ))  
left join image i on ( ci.catalog_image = i.image_id)
--where ce.catalog_entry_id in ( 4193180,4008480,4930 ,2133273,2188157,2188164,2190663,2191860,2191863) 
END_SQL

    $self->verbose(3, "SQL for Inserting:\n$sql\n");

    return $sql;
}


my $default_types = [qw/V380 PDF/];

sub create 
{

    my $self = shift; 

    my $output = GSI::DataX::GNC::Report::MissingImage::Files::Local->new->new_file->path;

    my $x = GSI::DataTranslate::Translator->new();

    my $verboseLevel = GSI::Utils::Verbose->get_level();

    my $output_columns =
       ["PID",
        "SKU",
	"PID status",
	"Global Category Name",
	"Global Category ID",
	"Product Long Title",
	"Label Status",
	"MFG Style Code"
        ];


    my $dbName = $self->{DB_NAME};
    my $storeCode  = $self->{STORE_CODE};
    my @element_types = @{$self->{ELEMENT_TYPE}};

    @element_types = @$default_types if (scalar (@element_types) == 0  );

    my @map =
    (
        DBQuery     => { SQL     => $self->_get_add_sql(\@element_types),
                         DB_NAME => $dbName,
                         BIND_PARAM => [ $storeCode ,@element_types ],
                       },

#        => SpaceRemove => {}

        => CSV       => { FILE_NAME    => $output,
                          COLUMNS      => $output_columns,
                          DELIMITER    => "\|",
                          HEADER       => 1,
                          #ALWAYS_QUOTE => 0,
                          QUOTE_CHAR   => undef,
                        }
    );

    $x->translate(MAP => \@map);

    return 1;
}

1;
