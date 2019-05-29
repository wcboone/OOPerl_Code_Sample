#
# $Id: Images.pm,v 1.3 2008/01/22 20:09:24 arnotts Exp $
#

use strict;

package GSI::DataX::GNC::Images;
our $VERSION = 1.00;

use GSI::DataX::GNC::Import;
use GSI::DataX::Images::Loader;
our @ISA = qw(GSI::DataX::GNC::Import GSI::DataX::Images::Loader);

use GSI::OptArg::ClassAttr
{
    SKUS            => { TYPE           => 'LIST',
                       },
    FILE_MATCHES    => { TYPE           => 'LIST',
                       },
    PARTNER_NAME    => { MODIFY         => 1,
                         REQUIRED       => 0,
                         DEFAULT        => 'GNC',
                       },
    PARTNER_DIR     => { MODIFY         => 1,
                         REQUIRED       => 0,
                         DEFAULT        => 'gnc',
                       },
    TABLE_NAME      => { MODIFY         => 1,
                         REQUIRED       => 0,
                         DEFAULT        => 'gnc_image',
                         ALIAS          => qw[IMAGE_TABLE_NAME],
                       },
    ACTIVE_FILE_SET => { MODIFY         => 1,
                         DEFAULT        => 'Stored',
                       },
    MATCH           => { TYPE           => 'Match',
                         MODIFY         => 1,
                         REQUIRED       => 0,
                         DEFAULT        =>
                           qr/^(\d+)(?:_([A-Za-z][^_]+))?\.(.+)$/,
                       },
    SIZING_CHAIN    => { MODIFY         => 1,
                         DEFAULT        =>
                           'file:authoring2/gnc_11_30_2007.chain',
                       },
};

1;
