require "rails_helper"
=begin
 * Created by PSU Beeminder Capstone Team on 3/12/2017.
 * Copyright (c) 2017 PSU Beeminder Capstone Team
 * This code is available under the "MIT License".
 * Please see the file LICENSE in this distribution for license terms.
=end

describe "Typeracer goals" do
  scenario "create completed games goal" do
    link_title = "Completed Games"

    user = create(:user)
    mock_current_user user
    mock_beeminder_goals(user, %w(slug1 slug2 slug3))
    mock_provider_score
    visit root_path

    expect(user.credentials).to be_empty
    expect(user.goals).to be_empty

    page.click_link(link_title)
    page.fill_in "credential_uid", with: "asdf"
    expect(TyperacerAdapter).to receive(:valid_credentials?)
      .with(
        "uid" => "asdf",
        "password" => ""
      ).and_return(true).at_least(:once)
    page.click_button "Save"
    expect(user.credentials.count).to eq(1)
    expect(user.credentials.first.provider_name).to eq("typeracer")
    expect(page.current_path).to eq(root_path)

    page.click_link(link_title)
    expect(page).to have_content "Typeracer Completed Games"
    expect(page).to have_content "Goal Configuration"

    page.select "slug2", from: "goal_slug"
    page.click_button "Save"
    expect(page).to have_content("Updated successfully!")
    expect(user.goals.count).to eq(1)
    goal = user.goals.first
    expect(goal.metric_key).to eq("completed_games")
    expect(goal.slug).to eq("slug2")
    expect(page).to have_css("#configured-goals", text: "Typeracer - Completed Games")

    page.click_link(link_title)
    expect(page).to have_select("goal_slug", selected: "slug2")
    click_link "Delete"
    expect(page).to have_content("Deleted successfully!")
    expect(user.reload.goals).to be_empty
  end
end
