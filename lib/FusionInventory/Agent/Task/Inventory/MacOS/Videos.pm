package FusionInventory::Agent::Task::Inventory::MacOS::Videos;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use FusionInventory::Agent::Tools;
use FusionInventory::Agent::Tools::MacOS;

sub isEnabled {
    my (%params) = @_;
    return 0 if $params{no_category}->{video};
    return canRun('/usr/sbin/system_profiler');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    foreach my $video (_getVideoCards(logger => $logger)) {
        $inventory->addEntry(
            section => 'VIDEOS',
            entry   => $video,
        );
    }
}

sub _getVideoCards {
    my (%params) = @_;

    my $infos = getSystemProfilerInfos(
        type   => 'SPDisplaysDataType',
        logger => $params{logger},
        file   => $params{file}
    );

    my @videos;

    foreach my $videoName (keys %{$infos->{'Graphics/Displays'}}) {
        my $videoCardInfo = $infos->{'Graphics/Displays'}->{$videoName};

        my $memory = $videoCardInfo->{'VRAM (Total)'} ||
            $videoCardInfo->{'VRAM (Dynamic, Max)'};
        $memory =~ s/\ .*//g if $memory;

        my $video = {
            CHIPSET    => $videoCardInfo->{'Chipset Model'},
            MEMORY     => $memory,
            NAME       => $videoName
        };

        foreach my $displayName (keys %{$videoCardInfo->{Displays}}) {
            next if $displayName eq 'Display Connector';
            next if $displayName eq 'Display';
            my $displayInfo = $videoCardInfo->{Displays}->{$displayName};

            my $resolution = $displayInfo->{Resolution};
            if ($resolution) {
                my ($x,$y) = $resolution =~ /(\d+) *x *(\d+)/;
                $resolution = $x.'x'.$y if $x && $y;
            }

            # Set first found resolution on associated video card
            $video->{RESOLUTION} = $resolution
                if $resolution && !$video->{RESOLUTION};
        }

        $video->{PCISLOT} = $videoCardInfo->{Bus}
            if defined($videoCardInfo->{Bus});
        $video->{PCISLOT} = $videoCardInfo->{Slot}
            if defined($videoCardInfo->{Slot});

        push @videos, $video;
    }

    return @videos;
}

1;
