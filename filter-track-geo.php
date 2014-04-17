<?php
/*
 * Most of this file comes from Phirehose's example file of the same name
 */

require_once('phirehose/lib/Phirehose.php');
require_once('phirehose/lib/OauthPhirehose.php');

require_once('config.php');

if ($argc != 5) {
    echo "Usage: $argv[0] lat_min long_min lat_max long_max\n";
    exit;
}

define("long_min", $argv[2]);
define("lat_min", $argv[1]);
define("long_max", $argv[4]);
define("lat_max", $argv[3]);

/**
 * Example of using Phirehose to display a live filtered stream using geo locations
 */
class FilterTrackConsumer extends OauthPhirehose
{
  /**
   * Enqueue each status
   *
   * @param string $status
   */
  public function enqueueStatus($status)
  {
    /*
     * In this simple example, we will just display to STDOUT rather than enqueue.
     * NOTE: You should NOT be processing tweets at this point in a real application, instead they should be being
     *       enqueued and processed asyncronously from the collection process.
     */
    $data = json_decode($status, true);
    /* Added some checks to only display results strictly inside the
     * provided coordinates (as it is not always the case)
     */
    if (is_array($data)
	&& isset($data['user']['screen_name'])
	&& isset($data['coordinates']['coordinates'][0])
	&& isset($data['coordinates']['coordinates'][1])
	&& ($data['coordinates']['coordinates'][0] >= long_min)
	&& ($data['coordinates']['coordinates'][0] <= long_max)
	&& ($data['coordinates']['coordinates'][1] >= lat_min)
	&& ($data['coordinates']['coordinates'][1] <= lat_max)
	) {
	/* Print user ID, tweet and coordinates */
	print $data['user']['screen_name'] . ': ' . urldecode($data['text']) . " [" . $data['coordinates']['coordinates'][1] . ", " . $data['coordinates']['coordinates'][0] . "]\n";
    }
  }
}

// Start streaming
$sc = new FilterTrackConsumer(OAUTH_TOKEN, OAUTH_SECRET, Phirehose::METHOD_FILTER);
$sc->setLocations(array(
		      array(long_min, lat_min, long_max, lat_max),
   ));
$sc->consume();
