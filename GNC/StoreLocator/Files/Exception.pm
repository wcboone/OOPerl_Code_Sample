#
# vim:ts=4:sw=4:sta:aw:ai:et:sr:nowrap
#=============================================================
# COPYRIGHT (c) 2007 GSI Commerce Inc
# All rights are reserved. Reproduction in whole or in part
# is prohibited without the written consent of the copyright
# owner.
#-------------------------------------------------------------
#
#System :    Perl
#Department: IST/Business Integration/Feeds
#Package :   GSI::
#File    :
#$Author: demij $
#Desc    :
#Date      Auth    Ref/Description
#--------- ------- ------------------------------------------
#
#
use strict;
use warnings;

package GSI::DataX::GNC::StoreLocator::Files::Exception;

use base qw( 
              GSI::File::Set::Combined
              GSI::File::Set::StandardDated 
              GSI::DataX::File::Set
            );

our $VERSION = sprintf( "%d.%02d", q$Revision: 1.1 $ =~ /(\d+)\.(\d+)/ );

use GSI::OptArg::ClassAttr
{
  NAME           => { MODIFY   => 1, 
                      DEFAULT  => "GNC Store Location Feed Load Exception File",
                    }, 
  FILE_TYPE      => { MODIFY   => 1, 
                      DEFAULT  => "ASCII",
                    }, 
  MODE           => { MODIFY   => 1, 
                      DEFAULT  => "READ",
                    }, 
  TEMPLATE       => { MODIFY   => 1, 
                      REQUIRED => 0,
                      DEFAULT  => '{X_DATA_ROOT}/exception/YYYYMMDDHHMMSS.csv',
                    },
};

package GSI::DataX::GNC::StoreLocator::Files::Exception::File;

use GSI::File::Set::Combined;
use GSI::File::Set::StandardDated;
use GSI::DataX::File::Set;

our @ISA = qw(GSI::File::Set::Combined::File
              GSI::File::Set::StandardDated::File 
              GSI::DataX::File::Set);

1;
