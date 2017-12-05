<?php
/**
 * Perfrom Maintencance tasks on the current
 * WordPress installations.
 * Run with wp-cli. Eg. `wp eval-file cron.php`
 */

/**
 * Don't run if not executied from WP_CLI
 */
if ( ! defined( 'WP_CLI' ) || ! WP_CLI ) {
	exit(1);
}

/**
 * Check if our theme has a `root-files`
 * directory and link it where nginx can find it
 */
function setRootFiles(){
	$theme_name = WP_CLI::runcommand( 'theme list --status=active --field=name', [ 'return' => true ]);
	$theme_path = WP_CLI::runcommand('theme path ' . $theme_name . ' --dir', [ 'return' => true ]);
	$root_files = implode( DIRECTORY_SEPARATOR, [ $theme_path, 'root-files' ] );
	$link = implode( DIRECTORY_SEPARATOR, [ __DIR__, 'theme' ] );

	if ( is_dir( $root_files ) && ! ( is_link( $link ) && readlink( $link ) === $root_files ) ) {
		if ( symlink( $root_files, $link ) ){
			WP_CLI::success( 'The symlink was created: '. $link . " -> " . $root_files );
			return;
		};

		WP_CLI::warning( 'The symlink could not be created: ' . $link );
		return;
	}

	if ( is_link( $link ) && ! is_readable( readlink( $link ) ) ) {
		if ( unlink( $link ) ) {
			WP_CLI::success( 'The symlink was removed: ' . $link );
			return;
		}

		WP_CLI::warning( 'The symlink could not be removed: ' . $link );
	}
}

/**
 * TASKS
 */
setRootFiles();
WP_CLI::runcommand( 'cron event run --due-now' );
