for( my $i = 0; $i < 0x8000000; $i = $i + 0x800 ){
	print 'send "nand dump ';

	printf("%lX", $i);
	print '"' . "\n";

	print 'expect {' . "\n";
        print '	"AAVK-EMG2926Q10A#"' . "\n";
	print '}' . "\n";
	print "\n";
}
