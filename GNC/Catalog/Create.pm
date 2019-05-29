#
# $Id: Create.pm,v 1.1 2011/10/31 18:11:38 demij Exp $
#

use strict;

package GSI::DataX::GNC::Catalog;

use GSI::DataX::GNC::Catalog::Files::Local;

use GSI::DataTranslate::Translator;

my $sql = <<"END_SQL";
  SELECT DISTINCT gc.catalog_entry_id     "CATALOG_ENTRY_ID",
                  gc.title                "TITLE",
                  sepn.category_path_name "CATEGORY_PATH_NAME",
                  sepn.category_path      "CATEGORY_PATH_ID"
  FROM catalog_entry ce  
  JOIN store_product sp ON ( sp.product_id = ce.catalog_entry_id
                           and  sp.store_code = 'GNC' 
                           --AND sp.sp_status LIKE 'A%'
                           )

  JOIN catalog_entry gc ON ( ce.global_cat_id = gc.catalog_entry_id )
  LEFT JOIN store_entry_path_name sepn ON  ( gc.catalog_entry_id = sepn.entry_id
                                          AND sepn.locale_code = 'en_US'
                                          and  sepn.store_code = sp.store_code 
                                         )
  WHERE  ce.entry_type = 'P'
    -- AND ce.status like 'A%'

--and gc.catalog_entry_id in ( )

ORDER BY gc.catalog_entry_id
END_SQL

#
# Public Methods
#
sub create
{
    my $self    = shift;
    my $dates   = $self->dates();
    my $date    = $dates->end || $dates->start if (defined($dates));
    my $out_set = GSI::DataX::GNC::Catalog::Files::Local->new();
    my $output;

    $date    = defined($date) ? $date->string() : 'today';
    $output  = $out_set->new_file(DATE => $date);

    my @map =
    (
           DBQuery     => {  DBH          => $self->database->handle(),
                            SQL          => $sql,
                          },

        => SpaceRemove => {}


        => CSV       => { FILE_NAME    => $output->{PATH}, 
                          DELIMITER       => "\t",
                          HEADER       => 1,
                        }
    );

    my $x = GSI::DataTranslate::Translator->new();
    $x->translate(MAP => \@map);
}

1;
