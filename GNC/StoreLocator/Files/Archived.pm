
use strict;

package GSI::DataX::GNC::StoreLocator::Files::Archived;

use GSI::DataX::GNC::Files::Remote;
use GSI::File::Set::Combined;
use GSI::File::Set::StandardDated;

our @ISA = qw(GSI::DataX::GNC::Files::Remote
              GSI::File::Set::Combined 
              GSI::File::Set::StandardDated);

use GSI::OptArg::ClassAttr
{
  NAME           => { MODIFY   => 1, 
                      DEFAULT  => "Archived GNC StoreLocator Files",
                    }, 
  TEMPLATE       => { MODIFY   => 1, 
                      REQUIRED => 0,
                      DEFAULT  => 'inbound/storelocator/processed/' .
                                  'YYYYMMDDHHMMSS.txt',
                    },
};

package GSI::DataX::GNC::StoreLocator::Files::Archived::File;

use GSI::DataX::GNC::Files::Remote;
use GSI::File::Set::Combined;
use GSI::File::Set::StandardDated;

our @ISA = qw(GSI::DataX::GNC::Files::Remote
              GSI::File::Set::Combined::File 
              GSI::File::Set::StandardDated::File);

1;
