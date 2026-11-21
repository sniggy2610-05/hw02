import { initializeTestEnvironment, assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { readFileSync } from 'fs';
import { serverTimestamp, doc, getDoc, setDoc, updateDoc, deleteDoc } from 'firebase/firestore';

const env = await initializeTestEnvironment({
  projectId: 'demo-hw02',
  firestore: { rules: readFileSync('../firestore.rules', 'utf8'), host: '127.0.0.1', port: 8080 },
});
await env.withSecurityRulesDisabled(async (ctx) => {
  await setDoc(doc(ctx.firestore(), 'messages/m1'),
    { text: 'hi', authorUid: 'ada', authorName: 'Ada', createdAt: new Date() });
});
const ada = env.authenticatedContext('ada').firestore();
const grace = env.authenticatedContext('grace').firestore();
const anon = env.unauthenticatedContext().firestore();

await assertFails(getDoc(doc(anon, 'messages/m1')));
console.log('PASS: signed-out read denied');
await assertFails(updateDoc(doc(grace, 'messages/m1'), { text: 'x', editedAt: serverTimestamp() }));
console.log('PASS: cross-uid update denied');
await assertFails(setDoc(doc(grace, 'messages/m2'),
  { text: 'x', authorUid: 'ada', authorName: 'x', createdAt: serverTimestamp() }));
console.log('PASS: forged authorUid create denied');
await assertSucceeds(setDoc(doc(ada, 'messages/m3'),
  { text: 'ok', authorUid: 'ada', authorName: 'Ada', createdAt: serverTimestamp() }));
console.log('PASS: correct-author create allowed');
await assertSucceeds(updateDoc(doc(ada, 'messages/m3'), { text: 'ok2', editedAt: serverTimestamp() }));
console.log('PASS: correct-author update allowed');
await assertSucceeds(deleteDoc(doc(ada, 'messages/m3')));
console.log('PASS: correct-author delete allowed');
console.log('ALL RULES TESTS PASSED');
await env.cleanup();
