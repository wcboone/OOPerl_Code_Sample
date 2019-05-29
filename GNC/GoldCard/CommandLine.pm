#
# $Id: CommandLine.pm,v 1.13 2007/01/19 23:06:34 donohuet Exp $
#

use strict;
use warnings;

package GSI::DataX::GNC::GoldCard::CommandLine;
our $VERSION = 1.00;

use GSI::DataX::GNC::GoldCard;
our @ISA = qw(GSI::DataX::GNC::Base::CommandLine);

my ($files,
    $download, $unzipit, $validate, $import,
    $export, $gather, $zipit, $upload,
    $report, $send,
    $checkimport, $checkexport);
my ($inputFile, $legacyFlag);
my $minRowCount;
my $store;
my $usequery;
my $useDB;
my $whichImportStep;
my (@mailTo, $mailFrom, @mailCC);
my ($ls_mode, $local, $remote);
my (@accountIds, @userIds);
my $mlpProgramId;


use GSI::OptArg::CommandLine (
    "usedb|usedatabase!"	=> \$useDB,
    "step|whichimportstep=s"	=> \$whichImportStep,
    "to|mailto=s"		=> \@mailTo,
    "from|mailfrom=s"		=> \$mailFrom,
    "cc|ccto=s"			=> \@mailCC,
    "files|ls|dir!"		=> \$files,
    "download!"			=> \$download,
    "unzip|unzipit|uncompress!"	=> \$unzipit,
    "validate!"			=> \$validate,
    "import!"			=> \$import,
    "export!"			=> \$export,
    "gather!"			=> \$gather,
    "zip|zipit|compress!"	=> \$zipit,
    "upload!"			=> \$upload,
    "report!"			=> \$report,
    "send!"			=> \$send,
    "checkimport!"		=> \$checkimport,
    "checkexport!"		=> \$checkexport,
    "lsmode=s"			=> \$ls_mode,
    "local!"			=> \$local,
    "remote!"			=> \$remote,
    "inputfile|file=s"		=> \$inputFile,
    "legacyflag|legacy!"	=> \$legacyFlag,
    "minrows|minrowcount=s"	=> \$minRowCount,	# to validate input file
    "aid|acctids|accountids=s"	=> \@accountIds,	# for debugging
    "uid|userids=s"		=> \@userIds,		# for debugging
    "mlpid=s"			=> \$mlpProgramId,
    "usequery=s"		=> \$usequery,
);


sub ui_init {
    my $ui_class = shift;
    $ui_class->verbose(5, "Entered ui_init() in ", __PACKAGE__, "\n");

    $ui_class->_action_mirror(Files		=> \$files,
			      Download		=> \$download,
			      Unzipit		=> \$unzipit,
			      Validate		=> \$validate,
			      Import		=> \$import,
			      Export		=> \$export,
			      CheckImport	=> \$checkimport,
			      CheckExport	=> \$checkexport,
			      Gather		=> \$gather,
			      Zipit		=> \$zipit,
			      Upload		=> \$upload,
			      Report		=> \$report,
			      Send		=> \$send);

    $ui_class->mirror('USE_DB',			\$useDB);
    $ui_class->mirror('INPUT_FILE',		\$inputFile);
    $ui_class->mirror('LEGACY_FLAG',		\$legacyFlag);
    $ui_class->mirror('MIN_ROW_COUNT',		\$minRowCount);
    $ui_class->mirror('LS_MODE',		\$ls_mode);
    $ui_class->mirror('LOCAL',			\$local);
    $ui_class->mirror('REMOTE',			\$remote);
    $ui_class->mirror('MAIL_FROM',		\$mailFrom);
    $ui_class->mirror('MLP_PROGRAM_ID',		\$mlpProgramId);
    $ui_class->mirror('WHICH_IMPORT_STEP',	\$whichImportStep);
    $ui_class->mirror('USE_QUERY',		\$usequery);
    $ui_class->mirror('STORE',			\$store);
}


sub ui_map_command_line {
    my $ui_class = shift;
    $ui_class->verbose(5, "Entered ui_map_command_line() in ",__PACKAGE__,"\n");

    $ui_class->mail_to(\@mailTo)		if (scalar @mailTo > 0);
    $ui_class->mail_cc(\@mailCC)			if (scalar @mailCC > 0);
    $ui_class->account_ids(\@accountIds)	if (scalar @accountIds > 0);
    $ui_class->user_ids(\@userIds)		if (scalar @userIds > 0);
}

#
# Public Methods
#

sub check_command_line_opts {
    my $class = shift;
    $class->verbose(5, "Entered check_command_line_opts() in ",__PACKAGE__,"\n");

    return 1;
}

1;
