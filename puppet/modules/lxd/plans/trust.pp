# @summary Distributes the local and remote keys to allow for migration using the local `lxc` command.
# @param targets The targets to run on.
plan lxd::trust
( TargetSpec $targets = get_targets('lxd')
)
{
	$target_names = get_targets($targets).map |$n| { $n.name }
	out::message("Trusting: ${target_names.join(', ')}")

	$targets.parallelize |$target|
	{
		log::debug("Gather remote keys on ${target.name}")
		$local_list_raw = run_command('lxc remote list --format json', $target)
		unless $local_list_raw.ok
		{
			fail_plan('local lxd remote query failed', 'task-unexpected-failure', { result => $local_list_raw, })
		}
		$local_result = $local_list_raw.ok_set[0]
		unless $local_result.status == 'success'
		{
			fail_plan('local lxd remote query unsuccessful', 'task-unexpected-failure', { result => $local_result, })
		}
		$local_list = $local_result.to_data['value']['stdout'].parsejson()
		$missing_remotes = $target_names - $local_list.keys
		out::message("missing remotes on ${target.name}: ${missing_remotes.join(', ')}")

		log::debug("Gather remote tokens for ${target.name}")
		$tokens = run_command("lxc config trust add --name ${target.name}", get_targets($missing_remotes))
			.map |$res|
			{
				unless $res.ok
				{
					fail_plan('remote lxd trust add failed', 'task-unexpected-failure', { result => $res, })
				}
				unless $res.status == 'success'
				{
					fail_plan('remote lxd trust add unsuccessful', 'task-unexpected-failure', { result => $res, })
				}
				$stdout = $res.to_data['value']['stdout']
				$token = $stdout.split("\n")[-1]
				[ $res.target.name, $token, ]
			}
			.convert_to(Hash)

		log::debug('Add remotes with tokens')
		$result = run_task('lxd::trust_local_add', $target, { tokens => $tokens, })
	}

	return $result
}
