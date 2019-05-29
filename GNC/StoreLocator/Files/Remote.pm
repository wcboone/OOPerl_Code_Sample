
use strict;

package GSI::DataX::GNC::StoreLocator::Files::Remote;

use GSI::DataX::GNC::Files::Remote;
use GSI::File::Set::FormatDated;

our @ISA = qw(GSI::DataX::GNC::Files::Remote
              GSI::File::Set::FormatDated);

use GSI::OptArg::ClassAttr
{
  NAME           => { MODIFY   => 1,
                      DEFAULT  => "Remote GNC StoreLocator Files",
                    },
  FILE_TYPE      => { MODIFY   => 1,
                      DEFAULT  => "ASCII",
                    },
  TEMPLATE       => { MODIFY   => 1,
                      REQUIRED => 0,
                      DEFAULT  => 'inbound/storeloc-%Y%m%d-%H%M%S.csv',
                      #DEFAULT  => 'inbound/STORELOC-%Y%m%d-%H%M%S.CSV',
                      #DEFAULT  => 'inbound/storelocator/storeloc.dat',
                      #DEFAULT  => 'inbound/storelocator/StoreLocator.txt',
                      #DEFAULT  => 'inbound/storelocator/%Y-%m-%d'.'T'.'%H%M%SStoreLocator.txt',
                    },
};

package GSI::DataX::GNC::StoreLocator::Files::Remote::File;

use GSI::DataX::GNC::Files::Remote;
use GSI::File::Set::FormatDated;

our @ISA = qw(GSI::DataX::GNC::Files::Remote::File
              GSI::File::Set::FormatDated::File);

1;
