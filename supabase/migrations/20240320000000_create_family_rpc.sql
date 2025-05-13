-- Create a function to create a family and add a member in a single transaction
create or replace function create_family_with_member(
  family_name text,
  user_id uuid,
  user_name text,
  is_parent boolean
) returns json
language plpgsql
security definer
as $$
declare
  new_family_id uuid;
  result json;
begin
  -- Create the family
  insert into families (name, created_by)
  values (family_name, user_id)
  returning id into new_family_id;

  -- Add the user as a family member
  insert into family_members (family_id, user_id)
  values (new_family_id, user_id);

  -- Return the created family data
  select json_build_object(
    'id', new_family_id,
    'name', family_name,
    'created_by', user_id
  ) into result;

  return result;
end;
$$;

-- Grant execute permission to authenticated users
grant execute on function create_family_with_member to authenticated; 