
use strict;

package GSI::DataX::GNC::Report::MissingImage::Files::Local;

use GSI::File::Set::StandardDated;
use GSI::DataX::File::Set;

our @ISA = qw(GSI::File::Set::StandardDated GSI::DataX::File::Set);

use GSI::OptArg::ClassAttr
{
  NAME         => { MODIFY   => 1, 
                    DEFAULT  => "Local Report Product Data Feed File",
                  }, 
  FILE_TYPE    => { MODIFY   => 1, 
                    DEFAULT  => "ASCII",
                  }, 
  MODE         => { MODIFY   => 1, 
                    DEFAULT  => "WRITE",
                  }, 
  TEMPLATE     => { MODIFY   => 1, 
                    REQUIRED => 0,
                    DEFAULT  => "{X_DATA_ROOT}/created/YYYYMMDDHHMM.csv",

                  },
  CLEAN_POLICY => { MODIFY   => 1,
                    DEFAULT  => '30 days ago',
                  },
};

package GSI::DataX::GNC::Report::MissingImage::Files::Local::File;

use GSI::File::Set::StandardDated;

our @ISA = qw(GSI::File::Set::StandardDated::File);

1;

