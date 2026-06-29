library draft_1.globals;

import "package:draft_1/model.dart";

Map<DateTime, List<Task>> tasksByDate = {};
List<Test> tests = [];

/// Flashcard decks available across the app. Seeded with a couple of starter
/// decks so AI-generated cards can be saved into an existing deck right away.
List<Deck> decks = [
  Deck(name: 'General'),
  Deck(name: 'Chemistry'),
];


       const String msg = '''
              {
                "id": "chatcmpl-9sHXItAiMKkAvtum8GzKwM5P9ukfs",
                "object": "chat.completion",
                "created": 1722724148,
                "model": "gpt-3.5-turbo-0125",
                "choices": [
                  {
                    "index": 0,
                    "message": {
                      "role": "assistant",
                      "content": {     
                        "study_plan": [        
                          {  
                            "date": "2024-10-15",            
                            "task": "Review the periodic table and key elements"       
                          },     
                          {
                            "date": "2024-10-16",           
                            "task": "Study chemical reactions and balancing equations"        
                          },      
                          {
                            "date": "2024-10-17",            
                            "task": "Review types of bonds and intermolecular forces"      
                          } ,       
                          {          
                            "date": "2024-10-18",            
                            "task": "Practice solving stoichiometry problems"     
                          },       
                          {
                            "date": "2024-10-19",            
                            "task": "Review all topics and do practice tests"      
                          }
                        ]}
                    },
                    "logprobs": null,
                    "finish_reason": "stop"
                  }
                ]
                }
                  ''';
