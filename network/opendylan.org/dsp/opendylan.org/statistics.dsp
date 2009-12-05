<%dsp:taglib name="od"/>

<od:standard-header>Gwydion Statistics</od:standard-header>

<P>The <EM>Testworks</EM> library provides a comprehensive set of testing
primitives enabling the <EM>Open Dylan</EM> and <EM>Gwydion
Dylan</EM> developers to monitor progress towards compliance with the
Dylan standard.</P>
<P>This page presents current test statistics for compliance with the
Dylan specification, as well as some performance data over time, showing
the time taken to run the tests and the amount of memory allocated.</P>

<?php

if (! file_exists("tmp-images/runtime.png")) {
	include ("/usr/lib/jpgraph/jpgraph.php");
	include ("/usr/lib/jpgraph/jpgraph_line.php");
	include ("/usr/lib/jpgraph/jpgraph_pie.php");
	include ("/usr/lib/jpgraph/jpgraph_pie3d.php");

	$db = db_connect();
	$query = "SELECT * FROM teststats where libraryname = 'libraries' and run_date = '" . date("Y-m-d") . "' and suitename <> 'benchmarks'";
	$res = mysql_query($query, $db);
	$err = mysql_error();

	if ($err) {
		echo "MySQL error occurred while retrieving test data.  Please notify <a href=bfulgham@debian.org>Brent</a>.";
		echo $err;
		exit;
	}

	$perf_query = "SELECT * FROM testrunstats where libraryname = 'libraries'";
	$perf_res = mysql_query($perf_query, $db);
	$err = mysql_error();
	if ($err) {
		echo "MySQL error occurred while retrieving performance data.  Please notify <a href=bfulgham@debian.org>Brent</a>.";
		echo $err;
		exit;
	}


	// Collect the data
	$i = 0;
	while ($myrow=mysql_fetch_array($res)) {
		$libraryname[$i] = $myrow[0];
		$testname[$i] = $myrow[1];
		$datay[$i] = array( $myrow[3], $myrow[4], $myrow[5], $myrow[6] );
		$i++;
	}

	// Create Test Data Charts
	for ($j = 0; $j < $i; $j++) {
		// Create the Pie Graph.
		$graph = new PieGraph(380,280,"auto",60);
		$graph->SetShadow();

		// Set A title for the plot
		$graph->title->Set($testname[$j]);
		$graph->title->SetFont(FF_VERDANA,FS_BOLD,18);
		$graph->title->SetColor("darkblue");
		$graph->legend->Pos(0.05,0.6);

		$pie = new PiePlot3d($datay[$j]);
		$pie->SetSize(0.4);
		$pie->SetCenter(0.4,0.4);
		$pie->SetAngle(50);
		$pie->value->SetFont(FF_ARIAL,FS_NORMAL,10);
		$pie->SetLegends(array("Passed", "Failed", "Crashed", "Not Executed"));
		$pie->SetLabelType(PIE_VALUE_ADJPERCENTAGE);
		$pie->ExplodeSlice(1); // Failed
									    
		$pie->SetTheme("earth");

		$graph->Add($pie);
		$graph->Stroke("tmp-images/" . $testname[$j] . ".png");
	}

	// Create performance charts
	// Collect the data
	$i = 0;
	while ($myrow=mysql_fetch_array($perf_res)) {
		$dates[$i] = $myrow[3];
		$run_datay[$i] = $myrow[1];
		$alloc_datay[$i] = $myrow[2]/1024;
		$i++;
	}

	// Show Runtimes
	$graph = new Graph(380,280,"auto",60);
	$graph->SetShadow();
	$graph->SetScale("textlin");
	$graph->SetMargin(80,40,40,40);
	$lineplot = new LinePlot($run_datay);
	$graph->Add($lineplot);

	// Set A title for the plot
	$graph->title->Set("Runtime");
	$graph->title->SetFont(FF_VERDANA,FS_BOLD,18);
	$graph->title->SetColor("darkblue");
	$graph->yaxis->title->Set("Runtime (Seconds)");
	$graph->yaxis->SetTitleMargin(50);
	$graph->yaxis->title->SetFont(FF_ARIAL,FS_NORMAL,10);
	$graph->xaxis->title->Set("Date");
	$graph->xaxis->title->SetAlign("center");
	$graph->xaxis->title->SetFont(FF_ARIAL,FS_NORMAL,10);
	$graph->xaxis->SetTickLabels($dates);

	$lineplot->SetColor("blue");

	$graph->Stroke("tmp-images/runtime.png");

	// Show Allocations
	$graph = new Graph(380,280,"auto",60);
	$graph->SetShadow();
	$graph->SetScale("textlin");
	$graph->SetMargin(80,40,40,40);
	$lineplot = new LinePlot($alloc_datay);
	$graph->Add($lineplot);

	// Set A title for the plot
	$graph->title->Set("Allocations");
	$graph->title->SetFont(FF_VERDANA,FS_BOLD,18);
	$graph->title->SetColor("darkblue");
	$graph->yaxis->title->Set("Allocated Kilobytes");
	$graph->yaxis->title->SetFont(FF_ARIAL,FS_NORMAL,10);
	$graph->yaxis->SetTitleMargin(50);
	$graph->xaxis->title->Set("Date");
	$graph->xaxis->title->SetAlign("center");
	$graph->xaxis->title->SetFont(FF_ARIAL,FS_NORMAL,10);
	$graph->xaxis->SetTickLabels($dates);

	$lineplot->SetColor("blue");

	$graph->Stroke("tmp-images/allocation.png");
}
?>

<table><tr>
	<td><image src="tmp-images/tests.png" width="380" height="280" alt="Test Results"></td>
	<td><image src="tmp-images/suites.png" width="380" height="280" alt="Suites Results"></td>
</tr><tr>
	<td><image src="tmp-images/checks.png" width="380" height="280" alt="Checks Results"></td>
	<td>Benchmarks Will Go Here *someday*</td>
</tr><tr>
	<td><image src="tmp-images/runtime.png" width="380" height="280" alt="Runtime Statistics"></td>
	<td><image src="tmp-images/allocation.png" width="380" height="280" alt="Allocation Statistics"></td>
</tr></table>
<div id="footer">
Charts produced by <a href="http://aditus.nu/jpgraph">JpGraph</a>.
</div>
<od:standard-footer/>
